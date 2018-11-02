#lang racket/base

(require db
         gregor
         racket/contract
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
    (match (query-row conn (select (coalesce (sum visits) 0)
                                   (hll_cardinality (hll_union_agg visitors))
                                   (hll_cardinality (hll_union_agg sessions))
                                   #:from page_visits
                                   #:where (and (>= date ,sql-start-date)
                                                (<  date ,sql-end-date))))
      [(vector visits visitors sessions)
       (hasheq 'visits visits
               'visitors (exact-floor visitors)
               'sessions (exact-floor sessions)
               'avg-time 0)]))

  (define (get-breakdown conn)
    (for/list ([(date host path referrer-host referrer-path visits visitors sessions)
                (in-query conn (select date host path referrer_host referrer_path
                                       (coalesce (sum visits) 0)
                                       (hll_cardinality (hll_union_agg visitors))
                                       (hll_cardinality (hll_union_agg sessions))
                                       #:from page_visits
                                       #:where (and (>= date ,sql-start-date)
                                                    (< date ,sql-end-date))
                                       #:group-by date host path referrer_host referrer_path))])

      (hasheq 'date (~t (sql-date->moment date) "yyyy-MM-dd")
              'host host
              'path path
              'referrer-host referrer-host
              'referrer-path referrer-path
              'visits visits
              'visitors (exact-floor visitors)
              'sessions (exact-floor sessions)
              'avg-time 0)))

  (call-with-database-transaction (reporter-database reporter)
    #:isolation 'repeatable-read
    (lambda (conn)
      (hasheq 'totals (get-totals conn)
              'breakdown (get-breakdown conn)))))


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

  (define (make-row date host path visits)
    (hasheq 'date date
            'host host
            'path path
            'referrer-host ""
            'referrer-path ""
            'visits visits
            'visitors 0
            'sessions 0
            'avg-time 0))

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
  page_visits(date, host, path, referrer_host, referrer_path, country, os, browser, visits)
values
  ('2018-08-20', 'example.com', '/', '', '', '', '', '', 10),
  ('2018-08-20', 'example.com', '/a', '', '', '', '', '', 1),
  ('2018-08-20', 'example.com', '/b', '', '', '', '', '', 2),
  ('2018-08-21', 'example.com', '/a', '', '', '', '', '', 3),
  ('2018-08-21', 'example.com', '/b', '', '', '', '', '', 5),
  ('2018-08-23', 'example.com', '/a', '', '', '', '', '', 1),
  ('2018-08-23', 'example.com', '/b', '', '', '', '', '', 2),
  ('2018-08-24', 'example.com', '/', '', '', '', '', '', 1)
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
               'breakdown (list (make-row "2018-08-20" "example.com" "/" 10)
                                (make-row "2018-08-20" "example.com" "/a" 1)
                                (make-row "2018-08-20" "example.com" "/b" 2)
                                (make-row "2018-08-21" "example.com" "/a" 3)
                                (make-row "2018-08-21" "example.com" "/b" 5)
                                (make-row "2018-08-23" "example.com" "/a" 1)
                                (make-row "2018-08-23" "example.com" "/b" 2))))))))
