#lang racket/base

(require component
         koyo/logging
         koyo/server
         "components/batcher.rkt"
         "components/current-visitors.rkt"
         "components/database.rkt"
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
  [database (make-database #:server config:db-host
                           #:port config:db-port
                           #:username config:db-username
                           #:password config:db-password
                           #:database config:db-name
                           #:max-connections config:db-max-connections
                           #:max-idle-connections config:db-max-idle-connections)]
  [geolocator make-geolocator]
  [migrator (database) make-migrator]
  [reporter (database) make-reporter]
  [server (app) (compose1 (make-server-factory #:host config:listen-ip
                                               #:port config:port)
                          app-dispatcher)])


(define (start)
  (define stop-logger
    (start-logger
     #:levels `((app      . ,config:log-level)
                (batcher  . ,config:log-level)
                (database . ,config:log-level)
                (migrator . ,config:log-level)
                (system   . ,config:log-level))))

  (system-start prod-system)

  (lambda ()
    (system-stop prod-system)
    (stop-logger)))

(module+ main
  (define stop (start))
  (with-handlers ([exn:break? (lambda _
                                (stop))])
    (sync/enable-break never-evt)))
