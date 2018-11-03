#lang racket/base

(require db
         gregor
         gregor/period
         racket/contract
         racket/list
         racket/match
         racket/math
         sql
         "database.rkt"
         "system.rkt"
         "utils.rkt")

(provide (contract-out
          [struct reporter ((database database?))]
          [make-reporter (-> database? reporter?)]
          [make-daily-report (-> reporter? date? date? hash?)]))

(struct reporter (database)
  #:methods gen:component
  [(define (component-start reporter) reporter)
   (define (component-stop reporter) (void))])

(define (make-reporter database)
  (reporter database))

(define (make-daily-report reporter start-date end-date)
  (define sql-start-date (date->sql-date start-date))
  (define sql-end-date (date->sql-date end-date))

  (define (get-totals conn)
    (match (query-row conn (select (as (coalesce (sum visits) 0) visits)
                                   (as (coalesce (hll_cardinality (hll_union_agg visitors)) 0) visitors)
                                   (as (coalesce (hll_cardinality (hll_union_agg sessions)) 0) sessions)
                                   #:from page_visits
                                   #:where (and (>= date ,sql-start-date)
                                                (<  date ,sql-end-date))))
      [(vector visits visitors sessions)
       (hasheq 'visits visits
               'visitors (exact-floor visitors)
               'sessions (exact-floor sessions)
               'avg-time 0)]))

  (define (get-timeseries conn)
    (define days-in-range (period-ref (period-between start-date end-date '(days)) 'days))
    (define start-date-string (~t start-date "YYYY-MM-dd"))
    (define sql-start-date (date->sql-date (-days start-date days-in-range)))
    (define sql-end-date (date->sql-date end-date))

    (define timeseries
      (for/list ([(date visits visitors sessions)
                  (in-query conn (select date
                                         (as (coalesce (sum visits) 0) visits)
                                         (as (coalesce (hll_cardinality (hll_union_agg visitors)) 0) visitors)
                                         (as (coalesce (hll_cardinality (hll_union_agg sessions)) 0) sessions)
                                         #:from page_visits
                                         #:where (and (>= date ,sql-start-date)
                                                      (<  date ,sql-end-date))
                                         #:group-by date
                                         #:order-by date #:asc))])
        (hasheq 'date (~t (sql-date->moment date) "YYYY-MM-dd")
                'visits visits
                'visitors (exact-floor visitors)
                'sessions (exact-floor sessions))))

    (define-values (previous-timeseries current-timeseries)
      (partition (lambda (ts)
                   (string<? (hash-ref ts 'date) start-date-string))
                 timeseries))

    (list previous-timeseries
          current-timeseries))

  (define (get-pages-breakdown conn)
    (for/list ([(host path visits visitors sessions)
                (in-query conn (select host path
                                       (as (coalesce (sum visits) 0) visits)
                                       (as (coalesce (hll_cardinality (hll_union_agg visitors)) 0) visitors)
                                       (as (coalesce (hll_cardinality (hll_union_agg sessions)) 0) sessions)
                                       #:from page_visits
                                       #:where (and (>= date ,sql-start-date)
                                                    (<  date ,sql-end-date))
                                       #:group-by host path
                                       #:order-by visits #:desc
                                       #:limit 30))])

      (hasheq 'host host
              'path path
              'visits visits
              'visitors (exact-floor visitors)
              'sessions (exact-floor sessions)
              'avg-time 0)))

  (define (get-referrers-breakdown conn)
    (for/list ([(referrer_host referrer_path visits visitors sessions)
                (in-query conn (select referrer_host referrer_path
                                       (as (coalesce (sum visits) 0) visits)
                                       (as (coalesce (hll_cardinality (hll_union_agg visitors)) 0) visitors)
                                       (as (coalesce (hll_cardinality (hll_union_agg sessions)) 0) sessions)
                                       #:from page_visits
                                       #:where (and (not (= referrer_host ""))
                                                    (>= date ,sql-start-date)
                                                    (<  date ,sql-end-date))
                                       #:group-by referrer_host referrer_path
                                       #:order-by visits #:desc
                                       #:limit 30))])

      (hasheq 'host referrer_host
              'path referrer_path
              'visits visits
              'visitors (exact-floor visitors)
              'sessions (exact-floor sessions)
              'avg-time 0)))

  (call-with-database-transaction (reporter-database reporter)
    #:isolation 'repeatable-read
    (lambda (conn)
      (hasheq 'totals (get-totals conn)
              'timeseries (get-timeseries conn)
              'pages-breakdown (get-pages-breakdown conn)
              'referrers-breakdown (get-referrers-breakdown conn)))))


(module+ test
  (require rackunit
           rackunit/text-ui
           (prefix-in config: "../config.rkt")
           "migrator.rkt")

  (define test-system
    (make-system `((database ,(make-database #:database "nemea_tests"
                                             #:username "nemea"
                                             #:password "nemea"))
                   (migrator [database] ,make-migrator)
                   (reporter [database] ,make-reporter))))

  (define (make-row host path visits)
    (hasheq 'host host
            'path path
            'visits visits
            'visitors 0
            'sessions 0
            'avg-time 0))

  (define (make-timeseries date visits)
    (hasheq 'date date
            'visits visits
            'visitors 0
            'sessions 0))

  (run-tests
   (test-suite
    "reporter"
    #:before
    (lambda ()
      (system-start test-system)

      (with-database-connection (conn (system-get test-system 'database))
        (query-exec conn "truncate page_visits")
        (query-exec conn #<<SQL
insert into
  page_visits(date, host, path, referrer_host, referrer_path, visits)
values
  ('2018-08-15', 'example.com', '/',  '',           '',   10),
  ('2018-08-17', 'example.com', '/',  '',           '',   8),
  ('2018-08-20', 'example.com', '/',  'google.com', '/a', 10),
  ('2018-08-20', 'example.com', '/a', '',           '',   1),
  ('2018-08-20', 'example.com', '/b', 'google.com', '/a', 2),
  ('2018-08-21', 'example.com', '/a', '',           '',   3),
  ('2018-08-21', 'example.com', '/b', '',           '',   5),
  ('2018-08-23', 'example.com', '/a', 'google.com', '/b', 1),
  ('2018-08-23', 'example.com', '/b', '',           '',   2),
  ('2018-08-24', 'example.com', '/',  '',           '',   1)
SQL
                    )))

    #:after (lambda () (system-stop test-system))

    (test-case "builds daily reports"
      (check-equal?
       (make-daily-report
        (system-get test-system 'reporter)
        (date 2018 8 20)
        (date 2018 8 24))
       (hasheq 'totals (hasheq 'visits 24 'sessions 0 'visitors 0 'avg-time 0)
               'timeseries (list
                            (list (make-timeseries "2018-08-17" 8))
                            (list (make-timeseries "2018-08-20" 13)
                                  (make-timeseries "2018-08-21" 8)
                                  (make-timeseries "2018-08-23" 3)))
               'pages-breakdown (list (make-row "example.com" "/" 10)
                                      (make-row "example.com" "/b" 9)
                                      (make-row "example.com" "/a" 5))
               'referrers-breakdown (list (make-row "google.com" "/a" 12)
                                          (make-row "google.com" "/b" 1))))))))
