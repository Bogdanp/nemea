#lang racket/base

(require db
         gregor)

(provide date->sql-date
         sql-date->date)

(define (date->sql-date d)
  (sql-date (->year d) (->month d) (->day d)))

(define (sql-date->date d)
  (date (sql-date-year d)
        (sql-date-month d)
        (sql-date-day d)))
