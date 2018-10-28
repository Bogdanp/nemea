#lang racket/base

(require racket/contract
         racket/runtime-path
         threading
         web-server/dispatch
         web-server/dispatchers/dispatch
         (prefix-in files: web-server/dispatchers/dispatch-files)
         (prefix-in sequencer: web-server/dispatchers/dispatch-sequencer)
         web-server/dispatchers/filesystem-map
         web-server/http
         web-server/servlet-dispatch
         "../components/batcher.rkt"
         "../components/database.rkt"
         "../components/reporter.rkt"
         "../components/system.rkt"
         "middleware.rkt"
         "reporting.rkt"
         "tracking.rkt"
         "utils.rkt")

(provide (contract-out
          (struct app ((dispatcher dispatcher/c)))
          (make-app (-> database? batcher? reporter? app?))))

(define-runtime-path parent-path ".")
(define static-path
  (build-path parent-path 'up 'up "static"))

(struct app (dispatcher)
  #:methods gen:component
  [(define (component-start app) app)
   (define (component-stop app) (void))])

(define (make-app database batcher reporter)
  (define file-server
    (files:make
     #:url->path (make-url->path static-path)))

  (define-values (dispatch _)
    (dispatch-rules
     [("track") (track-page-visit batcher)]
     [("v0" "reports" "daily") (get-daily-report reporter)]
     [else not-found]))

  (app (sequencer:make
        file-server
        (dispatch/servlet
         (~> dispatch
             handle-custom-exns)))))

(define (not-found req)
  (response/json #:body #hasheq((error . "not found"))))
