#lang racket/base

(require db
         gregor
         racket/contract
         sql
         "database.rkt"
         "system.rkt"
         "utils.rkt")

(provide (contract-out
          (struct reporter ((database database?)))
          (make-reporter (-> database? reporter?))
          (make-daily-report (-> reporter? date? date? (listof hash?)))))

(struct reporter (database)
  #:methods gen:component
  [(define (component-start reporter) reporter)
   (define (component-stop reporter) (void))])

(define (make-reporter database)
  (reporter database))

(define (make-daily-report reporter start-date end-date)
  (define conn (database-connection (reporter-database reporter)))
  (for/list ([(d path referrer-host visits)
              (in-query conn (select date path referrer_host visits
                                     #:from page_visits
                                     #:where (and (>= date ,(date->sql-date start-date))
                                                  (< date ,(date->sql-date end-date)))))])

    (hasheq 'date (sql-date->moment d)
            'path path
            'referrer-host referrer-host
            'visits visits)))

(module+ test
  (require rackunit
           rackunit/text-ui
           (prefix-in config: "../config.rkt")
           "migrations.rkt")

  (define test-system
    (make-system `((database ,(make-database #:database "nemea_tests"
                                             #:username "nemea"
                                             #:password "nemea"))
                   (migrations [database] ,make-migrations)
                   (reporter [database] ,make-reporter))))

  (run-tests
   (test-suite
    "reporter"
    #:before
    (lambda ()
      (system-start test-system)

      (query-exec (database-connection (system-get test-system 'database)) "truncate page_visits")
      (query-exec
       (database-connection (system-get test-system 'database))
       #<<SQL
insert into
  page_visits(date, path, referrer_host, referrer_path, country, os, browser, visits)
values
  ('2018-08-20', '/', '', '', '', '', '', 10),
  ('2018-08-20', '/a', '', '', '', '', '', 1),
  ('2018-08-20', '/b', '', '', '', '', '', 2),
  ('2018-08-21', '/a', '', '', '', '', '', 3),
  ('2018-08-21', '/b', '', '', '', '', '', 5),
  ('2018-08-23', '/a', '', '', '', '', '', 1),
  ('2018-08-23', '/b', '', '', '', '', '', 2),
  ('2018-08-24', '/', '', '', '', '', '', 1)
SQL
       ))

    #:after (lambda () (system-stop test-system))

    (test-case "builds daily reports"
      (check-equal?
       (make-daily-report
        (system-get test-system 'reporter)
        (date 2018 8 20)
        (date 2018 8 24))
       (list (hasheq 'date (moment 2018 8 20 #:tz config:timezone) 'path "/" 'referrer-host "" 'visits 10)
             (hasheq 'date (moment 2018 8 20 #:tz config:timezone) 'path "/a" 'referrer-host "" 'visits 1)
             (hasheq 'date (moment 2018 8 20 #:tz config:timezone) 'path "/b" 'referrer-host "" 'visits 2)
             (hasheq 'date (moment 2018 8 21 #:tz config:timezone) 'path "/a" 'referrer-host "" 'visits 3)
             (hasheq 'date (moment 2018 8 21 #:tz config:timezone) 'path "/b" 'referrer-host "" 'visits 5)
             (hasheq 'date (moment 2018 8 23 #:tz config:timezone) 'path "/a" 'referrer-host "" 'visits 1)
             (hasheq 'date (moment 2018 8 23 #:tz config:timezone) 'path "/b" 'referrer-host "" 'visits 2)))))))
