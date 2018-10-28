#lang racket/base

(require db
         racket/contract
         "system.rkt")

(provide (contract-out
          (struct database ((connection connection?)
                            (options database-opts?)))
          (make-database (->* (#:database string?
                               #:username string?
                               #:password string?)
                              (#:server string?
                               #:port exact-positive-integer?
                               #:max-connections exact-positive-integer?
                               #:max-idle-connections exact-positive-integer?)
                              (-> database?)))))

(struct database-opts (database username password server port max-connections max-idle-connections)
  #:transparent)

(struct database (connection options)
  #:methods gen:component
  [(define (component-start a-database)
     (define options (database-options a-database))
     (struct-copy database a-database
                  [connection (virtual-connection
                               (connection-pool
                                #:max-connections (database-opts-max-connections options)
                                #:max-idle-connections (database-opts-max-idle-connections options)
                                (lambda ()
                                  (postgresql-connect
                                   #:database (database-opts-database options)
                                   #:user (database-opts-username options)
                                   #:password (database-opts-password options)
                                   #:server (database-opts-server options)
                                   #:port (database-opts-port options)))))]))

   (define (component-stop database)
     (void))])

(define ((make-database #:database database-name
                        #:username username
                        #:password password
                        #:server [server "127.0.0.1"]
                        #:port [port 5432]
                        #:max-connections [max-connections 2]
                        #:max-idle-connections [max-idle-connections 1]))
  (database #f (database-opts database-name
                              username
                              password
                              server
                              port
                              max-connections
                              max-idle-connections)))

(module+ test
  (require rackunit)

  (define db (component-start ((make-database #:database "nemea_tests"
                                              #:username "nemea"
                                              #:password "nemea"))))

  (check-eq? (query-value (database-connection db) "select 1") 1))
