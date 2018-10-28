#lang racket/base

(require gregor
         racket/format
         racket/match
         web-server/web-server
         "components/batcher.rkt"
         "components/database.rkt"
         "components/migrations.rkt"
         "components/system.rkt"
         (prefix-in config: "config.rkt")
         "http/app.rkt"
         "http/server.rkt")

(define prod-system
  (make-system
   `((app [batcher database] ,make-app)
     (batcher [database] ,(make-batcher #:channel-size config:batcher-channel-size
                                        #:timeout config:batcher-timeout))
     (database ,(make-database #:server config:db-host
                               #:port config:db-port
                               #:username config:db-username
                               #:password config:db-password
                               #:database config:db-name
                               #:max-connections config:db-max-connections
                               #:max-idle-connections config:db-max-idle-connections))
     (migrations [database] ,make-migrations)
     (server [app] ,(make-server #:listen-ip config:listen-ip
                                 #:port config:port)))))

(module+ main
  (define log-receiver
    (make-log-receiver
     (current-logger)
     config:log-level 'app
     config:log-level 'batcher
     config:log-level 'database
     config:log-level 'migrations
     config:log-level 'server
     config:log-level 'system))

  (void
   (thread (lambda ()
             (let loop ()
               (match (sync log-receiver)
                 [(vector level message _ _)
                  (printf "[~a] [~a] ~a\n"
                          (~t (now/utc) "yyyy-MM-dd HH:mm:ss")
                          (~a level #:align 'right #:width 7)
                          message)
                  (loop)])))))

  (system-start prod-system)
  (with-handlers ([exn:break? (lambda (e)
                                (system-stop prod-system)
                                (sleep 1))])
    (semaphore-wait/enable-break (make-semaphore 0))))
