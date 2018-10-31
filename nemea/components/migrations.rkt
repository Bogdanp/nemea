#lang racket/base

(require (for-syntax racket)
         db
         racket/contract
         racket/file
         racket/list
         racket/match
         racket/path
         racket/runtime-path
         racket/string
         "database.rkt"
         "system.rkt")

(provide (contract-out
          [struct migrations ((database database?))]
          [make-migrations (-> database? migrations?)]))

(define-logger migrations)

(struct migrations (database)
  #:methods gen:component
  [(define (component-start migrations)
     (migrate! migrations)
     migrations)

   (define (component-stop migrations)
     (void))])

(define (make-migrations database)
  (-> database? migrations?)
  (migrations database))

(define-runtime-path parent-path ".")
(define migration-paths
  (sort
   (find-files
    (lambda (p)
      (string-suffix? (path->string p) ".sql"))
    (normalize-path (build-path parent-path 'up 'up "migrations")))
   string-ci<?))

(define (migrate-one! conn ref migration-path)
  (log-migrations-info "performing migration ~s" ref)
  (query-exec conn (file->string migration-path))
  (query-exec conn "insert into migrations values($1)" ref))

(define (migrate! migrations)
  (with-database-connection (conn (migrations-database migrations))
    (query-exec conn "create table if not exists migrations(ref text not null unique)")
    (define latest-ref
      (or (query-maybe-value conn "select ref from migrations") ""))

    (log-migrations-info "performing migrations")
    (for ([migration-path migration-paths])
      (define ref (path->string (last (explode-path migration-path))))
      (when (string-ci<? latest-ref ref)
        (call-with-transaction
          conn
          (lambda ()
            (migrate-one! conn ref migration-path))
          #:isolation 'serializable)))

    (log-migrations-info "migrations complete")))
