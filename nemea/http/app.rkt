#lang racket/base

(require threading
         racket/contract
         web-server/dispatch
         web-server/http
         "../components/batcher.rkt"
         "../components/database.rkt"
         "../components/reporter.rkt"
         "../components/system.rkt"
         "middleware.rkt"
         "reporting.rkt"
         "tracking.rkt"
         "utils.rkt")

(provide (contract-out
          (struct app ((start (-> request? response?))))
          (make-app (-> database? batcher? reporter? app?))))

(struct app (start)
  #:methods gen:component
  [(define (component-start app) app)
   (define (component-stop app) (void))])

(define (make-app database batcher reporter)
  (define-values (dispatch _)
    (dispatch-rules
     [("track") (track-page-visit batcher)]
     [("v0" "reports" "daily") (get-daily-report reporter)]
     [else not-found]))

  (app (~> dispatch
           handle-custom-exns)))

(define (not-found req)
  (response/json #:body #hasheq((error . "not found"))))
