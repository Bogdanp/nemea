#lang racket/base

(require component/base
         db
         db/util/postgresql
         gregor
         net/url
         racket/async-channel
         racket/contract
         racket/match
         racket/set
         threading
         (prefix-in config: "../config.rkt")
         "database.rkt"
         "page-visit.rkt"
         "utils.rkt")

(provide (contract-out
          [struct batcher ((database database?)
                           (events async-channel?)
                           (timeout exact-positive-integer?)
                           (listener-thread (or/c false/c thread?))
                           (timer-thread (or/c false/c thread?)))]

          [make-batcher (->* ()
                             (#:channel-size exact-positive-integer?
                              #:timeout exact-positive-integer?)
                             (-> database? batcher?))]

          [enqueue (-> batcher? page-visit? void?)]))

(define-logger batcher)

(struct batcher (database events timeout listener-thread timer-thread )
  #:methods gen:component
  [(define (component-start a-batcher)
     (log-batcher-debug "starting batcher")
     (struct-copy batcher a-batcher
                  [listener-thread (thread (make-listener a-batcher))]
                  [timer-thread (thread (make-timer a-batcher))]))

   (define (component-stop a-batcher)
     (log-batcher-debug "stopping batcher")
     (!> a-batcher 'stop)
     (kill-thread (batcher-timer-thread a-batcher))
     (thread-wait (batcher-listener-thread a-batcher))
     (struct-copy batcher a-batcher
                  [listener-thread #f]
                  [timer-thread #f]))])

(define ((make-batcher #:channel-size [channel-size 500]
                       #:timeout [timeout 60]) database)
  (batcher database (make-async-channel channel-size) timeout #f #f))

(define (!> batcher event)
  (async-channel-put (batcher-events batcher) event))

(define (enqueue batcher page-visit)
  (define date (today #:tz config:timezone))
  (async-channel-put (batcher-events batcher) (list date page-visit)))

(define ((make-listener batcher))
  (let loop ([batch (hash)])
    (match (async-channel-get (batcher-events batcher))
      ['stop
       (log-batcher-debug "received 'stop")
       (upsert-batch! batcher batch)
       (void)]

      ['timeout
       (log-batcher-debug "received 'timeout")
       (upsert-batch! batcher batch)
       (loop (hash))]

      [(list d pv)
       (loop (batch-aggregate batch d pv))])))

(define ((make-timer batcher))
  (let loop ()
    (sleep (batcher-timeout batcher))
    (log-batcher-debug "sending 'timeout")
    (!> batcher 'timeout)
    (loop)))

(define (batch-aggregate batch d pv)
  (define k (make-grouping d pv))
  (~>> (hash-ref batch k (list (set) (set) 0))
       (aggregate pv)
       (hash-set batch k)))

(define/match (aggregate pv agg)
  [(_ (list visitors sessions visits))
   (list (set-add visitors (page-visit-unique-id pv))
         (set-add sessions (page-visit-session-id pv))
         (add1 visits))])

(define (upsert-batch! batcher batch)
  (with-handlers ([exn:fail? (lambda (e)
                               (log-batcher-error "failed to upsert: ~a" (exn-message e)))])
    (call-with-database-transaction (batcher-database batcher)
      (lambda (conn)
        (for ([(grouping agg) (in-hash batch)])
          (upsert-agg! conn grouping agg))))))

(define/match (upsert-agg! conn grouping agg)
  [(_ _ (list visitors sessions visits))
   (query-exec conn UPSERT-BATCH-QUERY
               (date->sql-date (grouping-date grouping))
               (grouping-host grouping)
               (grouping-path grouping)
               (or (grouping-referrer-host grouping) "")
               (or (grouping-referrer-path grouping) "")
               visits
               (list->pg-array (set->list visitors))
               (list->pg-array (set->list sessions)))])

(define UPSERT-BATCH-QUERY
  #<<SQL
with
  visitors_agg as (select hll_add_agg(hll_hash_text(s.x)) as visitors from (select unnest($7::text[]) as x) as s),
  sessions_agg as (select hll_add_agg(hll_hash_text(s.x)) as sessions from (select unnest($8::text[]) as x) as s)
insert into page_visits(date, host, path, referrer_host, referrer_path, visits, visitors, sessions)
  values($1, $2, $3, $4, $5, $6, (select visitors from visitors_agg), (select sessions from sessions_agg))
on conflict(date, host, path, referrer_host, referrer_path)
do update
  set
    visits = page_visits.visits + $6,
    visitors = page_visits.visitors || (select visitors from visitors_agg),
    sessions = page_visits.sessions || (select sessions from sessions_agg)
  where
    page_visits.date = $1 and
    page_visits.host = $2 and
    page_visits.path = $3 and
    page_visits.referrer_host = $4 and
    page_visits.referrer_path = $5
SQL
  )

(struct grouping (date host path referrer-host referrer-path)
  #:transparent)

(define (make-grouping d pv)
  (grouping d
            (url->canonical-host (page-visit-location pv))
            (url->canonical-path (page-visit-location pv))
            (and~> (page-visit-referrer pv) (url->canonical-host))
            (and~> (page-visit-referrer pv) (url->canonical-path))))


(module+ test
  (require rackunit
           rackunit/text-ui
           "migrator.rkt")

  (define test-system
    (make-system `((database ,(make-database #:database "nemea_tests"
                                             #:username "nemea"
                                             #:password "nemea"))
                   (batcher (database) ,(make-batcher))
                   (migrator (database) ,make-migrator))))

  (run-tests
   (test-suite
    "Batcher"
    #:before
    (lambda ()
      (system-start test-system)
      (with-database-connection (conn (system-get test-system 'database))
        (query-exec conn "truncate page_visits")))

    #:after
    (lambda ()
      (system-stop test-system))

    (test-case "upserts visits"
      (enqueue (system-get test-system 'batcher) (page-visit "a" "b" (string->url "http://example.com/a") #f #f))
      (enqueue (system-get test-system 'batcher) (page-visit "a" "c" (string->url "http://example.com/a") #f #f))
      (!> (system-get test-system 'batcher) 'timeout)
      (sleep 0.1) ;; force the current thread to yield

      (check-equal?
       (with-database-connection (conn (system-get test-system 'database))
         (query-row conn "select visits, hll_cardinality(visitors), hll_cardinality(sessions) from page_visits order by date desc limit 1"))
       #(2 1.0 2.0))

      (enqueue (system-get test-system 'batcher) (page-visit "a" "b" (string->url "http://example.com/a") #f #f))
      (enqueue (system-get test-system 'batcher) (page-visit "a" "b" (string->url "http://example.com/a") #f #f))
      (enqueue (system-get test-system 'batcher) (page-visit "a" "b" (string->url "http://example.com/b") #f #f))
      (!> (system-get test-system 'batcher) 'stop)
      (sleep 0.1) ;; force the current thread to yield


      (check-eq?
       (with-database-connection (conn (system-get test-system 'database))
         (query-value conn "select visits from page_visits where path = '/a' order by date desc limit 1"))
       4)

      (check-eq?
       (with-database-connection (conn (system-get test-system 'database))
         (query-value conn "select visits from page_visits where path = '/b' order by date desc limit 1"))
       1)))))
