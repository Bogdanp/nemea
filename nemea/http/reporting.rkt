#lang racket/base

(require gregor
         json
         koyo/http
         koyo/json
         net/url
         racket/list
         web-server/http
         "../components/current-visitors.rkt"
         "../components/reporter.rkt"
         "common.rkt"
         "middleware.rkt")

(provide
 get-current-visitors
 get-daily-report)

(define ((get-current-visitors cv) req)
  (response/output
   #:mime-type #"text/event-stream"
   (lambda (out)
     (current-visitors-subscribe cv (current-thread))
     (parameterize ([current-output-port out])
       (let loop ()
         (define visitors (thread-receive))
         (send-event 'count (hash-count visitors))
         (send-event 'locations (lambda ()
                                  (write-json
                                   (remove-duplicates
                                    (for*/list ([(_ data) (in-hash visitors)]
                                                [location (in-value (cdr data))])
                                      (url->string location))))))
         (loop))))))

(define (send-event name data-or-writer)
  (display "event: ")
  (displayln name)
  (display "data: ")
  (cond
    [(procedure? data-or-writer) (data-or-writer)]
    [else (display data-or-writer)])
  (display "\n\n"))

(define ((get-daily-report reporter) req)
  (define bindings (request-bindings/raw req))
  (define start-date (string->date (bindings-ref bindings 'lo)))
  (define end-date (string->date (bindings-ref bindings 'hi)))
  (cond
    [(not start-date) (response/bad-request "start date missing")]
    [(not end-date) (response/bad-request "end date missing")]
    [(date<=? end-date start-date) (response/bad-request "start date must be less than end date")]

    [else
     (response/json (make-daily-report reporter start-date end-date))]))

(define (date->string d)
  (~t d "yyyy-MM-dd"))

(define (string->date s)
  (with-handlers ([exn:gregor:parse?
                   (lambda (e)
                     (bad-request "cannot parse date: ~s" s))])
    (and s (parse-date s "yyyy-MM-dd"))))


(module+ test
  (require rackunit
           rackunit/text-ui)

  (run-tests
   (test-suite
    "reporting"

    (test-suite
     "string->date"

     (test-eq?
      "#f produces #f"
      (string->date #f) #f)

     (test-equal?
      "valid dates produce date values"
      (string->date "2018-08-29")
      (date 2018 8 29))

     (test-exn
      "invalid dates produce bad-request errors"
      exn:bad-request?
      (lambda _
        (string->date "abc")))))))
