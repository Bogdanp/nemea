#lang racket/base

(require (for-syntax racket/base)
         component
         koyo/mime
         racket/contract
         racket/runtime-path
         threading
         web-server/dispatch
         web-server/dispatchers/dispatch
         (prefix-in files: web-server/dispatchers/dispatch-files)
         (prefix-in sequencer: web-server/dispatchers/dispatch-sequencer)
         web-server/dispatchers/filesystem-map
         web-server/servlet-dispatch
         "../components/batcher.rkt"
         "../components/current-visitors.rkt"
         "../components/database.rkt"
         "../components/migrator.rkt"
         "../components/reporter.rkt"
         "middleware.rkt"
         "reporting.rkt"
         "tracking.rkt")

(provide
 make-app
 app?
 app-dispatcher)

(define-runtime-path static-path
  (build-path 'up 'up "static"))

(define static-dispatcher
  (files:make
   #:url->path (make-url->path static-path)
   #:path->mime-type path->mime-type))

(struct app (dispatcher)
  #:methods gen:component
  [(define component-start values)
   (define component-stop values)])

(define/contract (make-app database migrator batcher current-visitors reporter)
  (-> database? migrator? batcher? current-visitors? reporter? app?)

  (define-values (dispatch _)
    (dispatch-rules
     [("track") (track-page-visit batcher current-visitors)]
     [("v0" "visitors-stream") (get-current-visitors current-visitors)]
     [("v0" "reports" "daily") (get-daily-report reporter)]
     [else (next-dispatcher)]))

  (app (sequencer:make
        (dispatch/servlet
         (~> dispatch
             wrap-custom-exns))
        static-dispatcher)))
