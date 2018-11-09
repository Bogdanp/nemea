#lang racket/base

(require racket/contract
         racket/match
         racket/set
         "system.rkt")

(provide (contract-out
          [struct current-visitors ((session-timeout exact-positive-integer?)
                                    (manager-thread (or/c false/c thread?)))]
          [make-current-visitors (->* ()
                                      (#:session-timeout exact-positive-integer?)
                                      current-visitors?)]
          [current-visitors-subscribe (-> current-visitors? thread? void?)]
          [current-visitors-track (-> current-visitors? string? void?)]))

(struct current-visitors (session-timeout (manager-thread #:mutable))
  #:methods gen:component
  [(define (component-start cv)
     (define session-timeout (current-visitors-session-timeout cv))
     (set-current-visitors-manager-thread! cv (thread (make-manager-thread session-timeout)))
     cv)

   (define (component-stop cv)
     (thread-send (current-visitors-manager-thread cv) 'stop))])

(define (make-current-visitors #:session-timeout [session-timeout 60])
  (current-visitors session-timeout #f))

(define ((make-manager-thread session-timeout))
  (let loop ([sessions (hash)]
             [listeners (set)])

    (sync
     (choice-evt
      (handle-evt
       (thread-receive-evt)
       (lambda (e)
         (match (thread-receive)
           ['stop (void)]

           ['broadcast
            (for ([listener listeners] #:unless (thread-dead? listener))
              (thread-send listener (hash-count sessions)))

            (loop sessions listeners)]

           [(list 'subscribe t)
            (loop sessions (set-add listeners t))]

           [(list 'track visitor-id)
            (loop (hash-set sessions visitor-id (current-seconds)) listeners)])))

      (handle-evt
       (alarm-evt (+ (current-inexact-milliseconds) 1000))
       (lambda (e)
         (define deadline (- (current-seconds) session-timeout))
         (define active-sessions (for/hash ([(visitor-id timestamp) (in-hash sessions)]
                                            #:unless (< timestamp deadline))
                                   (values visitor-id timestamp)))

         (thread-send (current-thread) 'broadcast)
         (loop active-sessions listeners)))))))

(define (current-visitors-subscribe current-visitors listener)
  (thread-send (current-visitors-manager-thread current-visitors)
               (list 'subscribe listener)))

(define (current-visitors-track current-visitors visitor-id)
  (thread-send (current-visitors-manager-thread current-visitors)
               (list 'track visitor-id)))

(module+ test
  (require rackunit
           rackunit/text-ui)

  (define last-count #f)
  (define waiter (make-semaphore))
  (define cv (make-current-visitors #:session-timeout 2))
  (define t1 (thread (lambda ()
                       (let loop ()
                         (set! last-count (thread-receive))
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
      (check-equal? last-count 0 "timeout after none tracked")

      (current-visitors-track cv "alice")
      (current-visitors-track cv "bob")
      (sync/timeout 2 waiter)
      (check-equal? last-count 2 "timeout after 2 tracked")

      (sync/timeout 2 waiter)
      (check-equal? last-count 2 "timeout after 2 tracked no. 2")

      (current-visitors-track cv "bob")
      (sync/timeout 2 waiter)
      (check-equal? last-count 1 "timeout after 1 tracked again")

      (sync/timeout 2 waiter)
      (sync/timeout 2 waiter)
      (check-equal? last-count 0 "two timeouts after none tracked")))))
