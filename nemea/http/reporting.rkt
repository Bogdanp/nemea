#lang racket/base

(require gregor
         json
         net/url
         racket/contract
         racket/list
         racket/string
         web-server/http
         "../components/current-visitors.rkt"
         "../components/reporter.rkt"
         "middleware.rkt"
         "utils.rkt")

(provide get-current-visitors
         get-daily-report)

(define ((get-current-visitors cv) req)
  (response/output
   #:mime-type #"text/event-stream"
   (lambda (out)
     (current-visitors-subscribe cv (current-thread))
     (parameterize ([current-output-port out])
       (let loop ()
         (define visitors (thread-receive))
         (printf "event: count\n")
         (printf "data: ~a\n\n" (hash-count visitors))
         (printf "event: locations\n")
         (printf "data: ~a\n\n" (jsexpr->string
                                 (remove-duplicates
                                  (for*/list ([(_ data) (in-hash visitors)]
                                              [location (in-value (cdr data))])
                                    (url->string location)))))
         (loop))))))

(define ((get-daily-report reporter) req)
  (define query (url-query (request-uri req)))
  (define start-date (string->date (assq* 'lo query)))
  (define end-date (string->date (assq* 'hi query)))
  (cond
    [(not start-date) (response/bad-request "start date missing")]
    [(not end-date) (response/bad-request "end date missing")]
    [(date<=? end-date start-date) (response/bad-request "start date must be less than end date")]

    [else
     (response/json #:body (make-daily-report reporter start-date end-date))]))

(define (date->string d)
  (~t d "yyyy-MM-dd"))

(define (string->date s)
  (with-handlers ([exn:gregor:parse?
                   (lambda (e)
                     (raise (exn:bad-request (format "cannot parse date: ~s" s) (current-continuation-marks))))])
    (and s (parse-date s "yyyy-MM-dd"))))


(module+ test
  (require rackunit)
  (check-eq? (string->date #f) #f)
  (check-equal? (string->date "2018-08-29") (date 2018 8 29))
  (check-exn
   exn:bad-request?
   (lambda ()
     (string->date "abc"))))
