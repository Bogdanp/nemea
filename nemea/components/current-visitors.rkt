#lang racket/base

(require component
         net/url
         racket/contract
         racket/list
         racket/match
         racket/set)

(provide (contract-out
          [struct current-visitors ((session-timeout exact-positive-integer?)
                                    (manager-thread (or/c false/c thread?)))]
          [make-current-visitors (->* ()
                                      (#:session-timeout exact-positive-integer?)
                                      current-visitors?)]
          [current-visitors-subscribe (-> current-visitors? thread? void?)]
          [current-visitors-track (-> current-visitors? string? url? void?)]))

(struct current-visitors (session-timeout (manager-thread #:mutable))
  #:methods gen:component
  [(define (component-start cv)
     (define session-timeout (current-visitors-session-timeout cv))
     (set-current-visitors-manager-thread! cv (thread (make-manager-thread session-timeout)))
     cv)

   (define (component-stop cv)
     (thread-send (current-visitors-manager-thread cv) 'stop)
     (set-current-visitors-manager-thread! cv #f)
     cv)])

(define (make-current-visitors #:session-timeout [session-timeout 60])
  (current-visitors session-timeout #f))

(define ((make-manager-thread session-timeout))
  (let loop ([visitors (hash)]
             [listeners (set)])

    (sync
     (choice-evt
      (handle-evt
       (thread-receive-evt)
       (lambda (e)
         (match (thread-receive)
           ['stop (void)]

           ['broadcast
            (define deadline (- (current-seconds) session-timeout))
            (define active-visitors
              (for*/hash ([(visitor-id data) (in-hash visitors)]
                          [timestamp (in-value (car data))]
                          #:unless (< timestamp deadline))
                (values visitor-id data)))

            (define active-listeners
              (for/set ([listener (in-set listeners)] #:unless (thread-dead? listener))
                (begin0 listener
                  (thread-send listener active-visitors))))

            (loop active-visitors active-listeners)]

           [(list 'subscribe t)
            (thread-send t visitors)
            (loop visitors (set-add listeners t))]

           [(list 'track visitor-id location)
            (thread-send (current-thread) 'broadcast)
            (loop (hash-set visitors visitor-id (cons (current-seconds) location)) listeners)])))

      (handle-evt
       (alarm-evt (+ (current-inexact-milliseconds) 1000))
       (lambda (e)
         (thread-send (current-thread) 'broadcast)
         (loop visitors listeners)))))))

(define (current-visitors-subscribe current-visitors listener)
  (thread-send (current-visitors-manager-thread current-visitors)
               (list 'subscribe listener)))

(define (current-visitors-track current-visitors visitor-id location)
  (thread-send (current-visitors-manager-thread current-visitors)
               (list 'track visitor-id location)))

(module+ test
  (require rackunit
           rackunit/text-ui)

  (define waiter (make-semaphore))
  (define cv (make-current-visitors #:session-timeout 2))

  (define counts '())
  (define t1
    (thread
     (lambda ()
       (let loop ()
         (set! counts (cons (hash-count (thread-receive)) counts))
         (semaphore-post waiter)
         (loop)))))

  (run-tests
   (test-suite
    "current-visitors"
    #:before
    (lambda ()
      (component-start cv)
      (current-visitors-subscribe cv t1))

    #:after
    (lambda ()
      (component-stop cv))

    (test-case "tracking"
      (sync/timeout 2 waiter)
      (check-equal? counts '(0) "timeout after none tracked")

      (current-visitors-track cv "alice" (string->url "http://example.com"))
      (current-visitors-track cv "bob" (string->url "http://example.com"))
      (sync/timeout 2 waiter) ; broadcast for alice
      (sync/timeout 2 waiter) ; broadcast for bob
      (sync/timeout 2 waiter) ; timeout
      (check-equal? counts '(2 2 2 0) "timeout after alice and bob tracked")

      (sync/timeout 2 waiter) ; timeout
      (check-equal? counts '(2 2 2 2 0) "timeout after alice and bob tracked no. 2")

      (current-visitors-track cv "bob" (string->url "http://example.com"))
      (sync/timeout 2 waiter) ; broadcast for bob
      (sync/timeout 2 waiter) ; timeout
      (check-equal? counts '(1 2 2 2 2 2 0) "timeout after bob tracked again")

      (sync/timeout 2 waiter) ; timeout
      (sync/timeout 2 waiter) ; timeout
      (check-equal? counts '(0 1 1 2 2 2 2 2 0) "2 timeouts after bob tracked again no. 2")))))
