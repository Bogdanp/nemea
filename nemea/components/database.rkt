#lang racket/base

(require component
         db
         racket/class
         racket/contract
         (for-syntax racket/base
                     racket/syntax
                     syntax/parse))

(provide (contract-out
          [struct database ((connection-pool connection-pool?)
                            (options database-opts?))]
          [make-database (->* (#:database string?
                               #:username string?
                               #:password string?)
                              (#:server string?
                               #:port exact-positive-integer?
                               #:max-connections exact-positive-integer?
                               #:max-idle-connections exact-positive-integer?)
                              (-> database?))]
          [call-with-database-connection (-> database? (-> connection? any/c) any/c)]
          [call-with-database-transaction (->* (database? (-> connection? any/c))
                                               (#:isolation (or/c 'serializable
                                                                  'repeatable-read
                                                                  'read-committed
                                                                  'read-uncommitted
                                                                  false/c)) any/c)])

         with-database-connection
         with-database-transaction)

(struct database-opts (database username password server port max-connections max-idle-connections)
  #:transparent)

(struct database (connection-pool options)
  #:methods gen:component
  [(define (component-start a-database)
     (define options (database-options a-database))
     (struct-copy database a-database
                  [connection-pool (connection-pool
                                    #:max-connections (database-opts-max-connections options)
                                    #:max-idle-connections (database-opts-max-idle-connections options)
                                    (lambda ()
                                      (postgresql-connect
                                       #:database (database-opts-database options)
                                       #:user (database-opts-username options)
                                       #:password (database-opts-password options)
                                       #:server (database-opts-server options)
                                       #:port (database-opts-port options))))]))

   (define (component-stop a-database)
     (struct-copy database a-database [connection-pool #f]))])

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

(define (call-with-database-connection database proc)
  (define pool (database-connection-pool database))
  (define connection (connection-pool-lease pool))
  (dynamic-wind
    (lambda () #f)
    (lambda () (proc connection))
    (lambda () (disconnect connection))))

(define-syntax-rule (with-database-connection [name database] e ...)
  (call-with-database-connection database
    (lambda (name)
      e ...)))

(define (call-with-database-transaction database proc #:isolation [isolation #f])
  (with-database-connection (conn database)
    (call-with-transaction conn
      #:isolation isolation
      (lambda () (proc conn)))))

(define-syntax (with-database-transaction stx)
  (syntax-parse stx
    [(_ [name:id database:expr] e:expr ...+)
     #'(with-database-transaction (name database)
         #:isolation #f
         e ...)]

    [(_ [name:id database:expr] #:isolation isolation e:expr ...+)
     #'(call-with-database-transaction database
         #:isolation isolation
         (lambda (name)
           e ...))]))

(module+ test
  (require rackunit)

  (define db (component-start ((make-database #:database "nemea_tests"
                                              #:username "nemea"
                                              #:password "nemea"))))

  (check-eq?
   (call-with-database-connection db
     (lambda (conn)
       (query-value conn "select 1")))
   1)

  (check-eq?
   (with-database-connection [conn db]
     (query-value conn "select 1"))
   1)

  (check-eq?
   (with-database-transaction [conn db]
     (query-value conn "select 1"))
   1)

  (check-eq?
   (with-database-transaction [conn db]
     #:isolation 'repeatable-read
     (query-value conn "select 1"))
   1))
