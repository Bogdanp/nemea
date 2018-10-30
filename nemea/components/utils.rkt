#lang racket/base

(require db
         gregor
         (prefix-in config: "../config.rkt"))

(provide date->sql-date
         sql-date->moment)

(define (date->sql-date d)
  (sql-date (->year d) (->month d) (->day d)))

(define (sql-date->moment d)
  (moment (sql-date-year d)
          (sql-date-month d)
          (sql-date-day d)
          #:tz config:timezone))
