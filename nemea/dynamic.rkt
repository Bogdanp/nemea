#lang racket/base

(require component
         (only-in db
                  postgresql-connect)
         koyo/database
         koyo/logging
         koyo/server
         "components/batcher.rkt"
         "components/current-visitors.rkt"
         "components/geolocator.rkt"
         "components/migrator.rkt"
         "components/reporter.rkt"
         (prefix-in config: "config.rkt")
         "http/app.rkt")

(provide
 prod-system
 start)

(define-system prod
  [app (database migrator batcher current-visitors reporter) make-app]
  [batcher (database geolocator) (make-batcher #:channel-size config:batcher-channel-size
                                               #:timeout config:batcher-timeout)]
  [current-visitors make-current-visitors]
  [database (make-database-factory
             #:max-connections config:db-max-connections
             #:max-idle-connections config:db-max-idle-connections
             (lambda _
               (postgresql-connect
                #:database config:db-name
                #:user     config:db-username
                #:password config:db-password
                #:server   config:db-host
                #:port     config:db-port)))]
  [geolocator make-geolocator]
  [migrator (database) make-migrator]
  [reporter (database) make-reporter]
  [server (app) (compose1
                 (make-server-factory
                  #:host config:host
                  #:port config:port)
                 app-dispatcher)])

(define (start)
  (define stop-logger
    (start-logger
     #:levels `((app        . ,config:log-level)
                (batcher    . ,config:log-level)
                (database   . ,config:log-level)
                (http-error . ,config:log-level)
                (migrator   . ,config:log-level)
                (system     . ,config:log-level))))

  (system-start prod-system)

  (lambda ()
    (system-stop prod-system)
    (stop-logger)))

(module+ main
  (define stop (start))
  (with-handlers ([exn:break? (lambda _
                                (stop))])
    (sync/enable-break never-evt)))
