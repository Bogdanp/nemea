#lang racket/base

(require racket/contract
         racket/generic
         racket/list
         racket/match)

(provide gen:component
         component?
         component-start
         component-stop

         (struct-out system)
         make-system
         system-start
         system-stop
         system-restart
         system-get)

(define-logger system)

(define-generics component
  (component-start component)
  (component-stop component))

(struct system (definitions references components))

(define (group h x ys)
  (foldl (lambda (y acc)
           (hash-set acc y (cons x (hash-ref acc y '()))))
         h ys))

(define/contract (make-system spec)
  (-> (listof (or/c
               (list/c symbol? any/c)
               (list/c symbol? (listof symbol?) any/c)))
      system?)

  (define definitions
    (for/hash ([definition spec])
      (match definition
        [(list id e)
         (values id (list '() e))]

        [(list id dep-ids e)
         (values id (list dep-ids e))]

        [else
         (error 'system-spec "bad component definition ~a" definition)])))

  (define references
    (let collect ([definitions (hash->list definitions)]
                  [references (hasheq)])
      (match definitions
        [(? empty?) references]
        [(cons (cons id (list dep-ids _)) definitions)
         (collect definitions (group references id dep-ids))])))

  (system definitions references (make-hasheq)))

(define/contract (system-start system)
  (-> system? void?)

  (define definitions (system-definitions system))
  (define components (system-components system))

  (define (start id)
    (match (hash-ref definitions id)
      [(list dep-ids e)
       (define deps (map lookup-or-start dep-ids))
       (define component (component-start (apply e deps)))
       (log-system-debug "started component ~e" id)
       (hash-set! components id component)
       component]))

  (define (lookup-or-start id)
    (match (hash-ref components id #f)
      [#f (start id)]
      [component component]))

  (for-each lookup-or-start (hash-keys definitions)))

(define/contract (system-stop system)
  (-> system? void?)

  (define references (system-references system))
  (define components (system-components system))

  (define (stop id)
    (define component (hash-ref components id #f))
    (when component
      (for-each stop (hash-ref references id '()))
      (component-stop component)
      (hash-remove! components id)
      (log-system-debug "stopped component ~e" id)))

  (for-each stop (hash-keys references)))

(define/contract (system-restart system)
  (-> system? void?)
  (system-stop system)
  (system-start system))

(define/contract (system-get system id)
  (-> system? symbol? any/c)
  (hash-ref (system-components system) id))


(module+ test
  (require rackunit)

  (define events '())

  (struct db ()
    #:transparent
    #:methods gen:component
    [(define (component-start db)
       (set! events (cons 'db-started events))
       db)

     (define (component-stop db)
       (set! events (cons 'db-stopped events)))])

  (define (make-db)
    (db))

  (struct a-service ()
    #:transparent
    #:methods gen:component
    [(define (component-start a-service)
       (set! events (cons 'a-service-started events))
       a-service)

     (define (component-stop a-service)
       (set! events (cons 'a-service-stopped events))
       a-service)])

  (define (make-a-service db)
    (check-eq? db (system-get test-system 'db))
    (a-service))

  (struct app ()
    #:transparent
    #:methods gen:component
    [(define (component-start app)
       (set! events (cons 'app-started events))
       app)

     (define (component-stop app)
       (set! events (cons 'app-stopped events))
       app)])

  (define (make-app db a-service)
    (check-eq? db (system-get test-system 'db))
    (check-eq? a-service (system-get test-system 'a-service))
    (app))

  (define test-system
    (make-system `((db ,make-db)
                   (app [db a-service] ,make-app)
                   (a-service [db] ,make-a-service))))

  (system-start test-system)
  (system-stop test-system)
  (check-equal?
   (reverse events)
   '(db-started a-service-started app-started app-stopped a-service-stopped db-stopped)))
