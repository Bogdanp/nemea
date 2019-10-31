#lang racket/base

(require (for-syntax racket/base)
         component
         db
         koyo/database
         racket/contract
         racket/file
         racket/list
         racket/match
         racket/path
         racket/runtime-path
         racket/string)

(provide
 make-migrator
 migrator?)

(define-logger migrator)

(struct migrator (database)
  #:methods gen:component
  [(define (component-start migrator)
     (begin0 migrator
       (migrate! migrator)))

   (define (component-stop _)
     (migrator #f))])

(define/contract (make-migrator database)
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

(define (migrate! migrator)
  (with-database-connection [conn (migrator-database migrator)]
    (query-exec conn "create table if not exists migrations(ref text not null unique)")
    (define latest-ref
      (or (query-maybe-value conn "select ref from migrations order by ref desc limit 1") ""))

    (log-migrator-info "performing migrations")
    (for ([migration-path migration-paths])
      (define ref (path->string (last (explode-path migration-path))))
      (when (string-ci<? latest-ref ref)
        (with-database-transaction [conn (migrator-database migrator)]
          #:isolation 'serializable
          (log-migrator-info "performing migration ~s" ref)
          (query-exec conn (file->string migration-path))
          (query-exec conn "insert into migrations values($1)" ref))))

    (log-migrator-info "migrations complete")))
