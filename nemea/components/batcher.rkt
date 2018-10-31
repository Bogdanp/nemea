#lang racket/base

(require db
         gregor
         net/url
         racket/async-channel
         racket/contract
         racket/match
         threading
         (prefix-in config: "../config.rkt")
         "database.rkt"
         "page-visit.rkt"
         "system.rkt"
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

   (define (component-stop batcher)
     (log-batcher-debug "stopping batcher")
     (!> batcher 'stop)
     (kill-thread (batcher-timer-thread batcher))
     (thread-wait (batcher-listener-thread batcher)))])

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
       (define k (make-grouping d pv))
       (loop (~>> (hash-ref batch k 0)
                  (add1)
                  (hash-set batch k)))])))

(define ((make-timer batcher))
  (let loop ()
    (sleep (batcher-timeout batcher))
    (log-batcher-debug "sending 'timeout")
    (!> batcher 'timeout)
    (loop)))

(define (upsert-batch! batcher batch)
  (with-handlers ([exn:fail? (lambda (e)
                               (log-batcher-error "failed to upsert: ~a" (exn-message e)))])
    (call-with-database-transaction (batcher-database batcher)
      (lambda (conn)
        (for ([(grouping visits) (in-hash batch)])
          (upsert-visits! conn grouping visits))))))

(define (upsert-visits! conn grouping visits)
  (query-exec conn UPSERT-BATCH-QUERY
              (date->sql-date (grouping-date grouping))
              (grouping-host grouping)
              (grouping-path grouping)
              (or (grouping-referrer-host grouping) "")
              (or (grouping-referrer-path grouping) "")
              (or (grouping-country grouping) "")
              (or (grouping-os grouping) "")
              (or (grouping-browser grouping) "")
              visits))

(define UPSERT-BATCH-QUERY
  #<<SQL
insert into page_visits(date, host, path, referrer_host, referrer_path, country, os, browser, visits)
  values($1, $2, $3, $4, $5, $6, $7, $8, $9)
on conflict(date, host, path, referrer_host, referrer_path, country, os, browser)
do update
  set visits = page_visits.visits + $9
  where
    page_visits.date = $1 and
    page_visits.host = $2 and
    page_visits.path = $3 and
    page_visits.referrer_host = $4 and
    page_visits.referrer_path = $5 and
    page_visits.country = $6 and
    page_visits.os = $7 and
    page_visits.browser = $8
SQL
  )

(struct grouping (date host path referrer-host referrer-path country os browser)
  #:transparent)

(define (make-grouping d pv)
  (grouping d
            (url-host (page-visit-location pv))
            (url->path-string (page-visit-location pv))
            (and~> (page-visit-client-referrer pv) (url-host))
            (and~> (page-visit-client-referrer pv) (url->path-string))
            "" "" ""))

(define (url->path-string url)
  (path->string (url->path url)))


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
      (enqueue (system-get test-system 'batcher) (page-visit (string->url "http://example.com/a") #f 1 #f))
      (enqueue (system-get test-system 'batcher) (page-visit (string->url "http://example.com/a") #f 1 #f))
      (!> (system-get test-system 'batcher) 'timeout)
      (sleep 0.1) ;; force the current thread to yield

      (check-eq?
       (with-database-connection (conn (system-get test-system 'database))
         (query-value conn "select visits from page_visits order by date desc limit 1"))
       2)

      (enqueue (system-get test-system 'batcher) (page-visit (string->url "http://example.com/a") #f 1 #f))
      (enqueue (system-get test-system 'batcher) (page-visit (string->url "http://example.com/a") #f 1 #f))
      (enqueue (system-get test-system 'batcher) (page-visit (string->url "http://example.com/b") #f 1 #f))
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
