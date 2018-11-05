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
          [struct migrator ((database database?))]
          [make-migrator (-> database? migrator?)]))

(define-logger migrator)

(struct migrator (database)
  #:methods gen:component
  [(define (component-start migrator)
     (migrate! migrator)
     migrator)

   (define (component-stop migrator)
     (void))])

(define (make-migrator database)
  (-> database? migrator?)
  (migrator database))

(define-runtime-path migrations-path
  (build-path 'up 'up "migrations"))

(define migration-paths
  (sort
   (find-files
    (lambda (p)
      (string-suffix? (path->string p) ".sql"))
    (normalize-path migrations-path))
   (lambda (a b)
     (string-ci<? (path->string a)
                  (path->string b)))))

(define (migrate-one! conn ref migration-path)
  (log-migrator-info "performing migration ~s" ref)
  (query-exec conn (file->string migration-path))
  (query-exec conn "insert into migrations values($1)" ref))

(define (migrate! migrator)
  (with-database-connection (conn (migrator-database migrator))
    (query-exec conn "create table if not exists migrations(ref text not null unique)")
    (define latest-ref
      (or (query-maybe-value conn "select ref from migrations order by ref desc limit 1") ""))

    (log-migrator-info "performing migrations")
    (for ([migration-path migration-paths])
      (define ref (path->string (last (explode-path migration-path))))
      (when (string-ci<? latest-ref ref)
        (call-with-transaction
          conn
          (lambda ()
            (migrate-one! conn ref migration-path))
          #:isolation 'serializable)))

    (log-migrator-info "migrations complete")))
