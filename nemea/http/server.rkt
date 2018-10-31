#lang racket/base

(require racket/contract
         web-server/servlet-dispatch
         web-server/web-server
         "../components/system.rkt"
         "app.rkt")

(provide (contract-out
          [struct server ((options server-opts?)
                          (app app?)
                          (stopper (or/c false/c (-> void?))))]

          [make-server (->* ()
                            (#:listen-ip string?
                             #:port exact-positive-integer?)
                            (-> app? server?))]))

(struct server-opts (listen-ip port)
  #:transparent)

(struct server (options app stopper)
  #:methods gen:component
  [(define (component-start a-server)
     (define options (server-options a-server))
     (define stopper (serve #:dispatch (app-dispatcher (server-app a-server))
                            #:listen-ip (server-opts-listen-ip options)
                            #:port (server-opts-port options)))

     (struct-copy server a-server [stopper stopper]))

   (define (component-stop server)
     ((server-stopper server)))])

(define ((make-server #:listen-ip [listen-ip "127.0.0.1"]
                      #:port [port 8000]) app)
  (server (server-opts listen-ip port) app #f))
