#lang racket/base

(require net/url
         racket/function
         racket/set
         racket/string
         threading
         web-server/http
         (prefix-in config: "../config.rkt")
         "../components/batcher.rkt"
         "../components/current-visitors.rkt"
         "../components/page-visit.rkt"
         "middleware.rkt"
         "utils.rkt")

(provide track-page-visit)

;; This is on the "hot path" so it has no contract.
(define ((track-page-visit batcher current-visitors) req)
  (when (track? req)
    (define page-visit (request->page-visit req))
    (current-visitors-track current-visitors
                            (page-visit-unique-id page-visit)
                            (page-visit-location page-visit))
    (enqueue batcher page-visit))
  (response/pixel))

(define (track? req)
  (not (or (do-not-track? req)
           (spammer? req))))

(module+ test
  (require koyo/testing
           rackunit)

  (check-true (track? (make-test-request)))
  (check-false (track? (make-test-request #:headers (list (make-header #"DNT" #"1"))))))


(define (do-not-track? req)
  (and~> (headers-assq* #"DNT" (request-headers/raw req))
         (header-value)
         (bytes=? #"1")))

(module+ test
  (check-false (do-not-track? (make-test-request)))
  (check-false (do-not-track? (make-test-request #:headers (list (make-header #"DNT" #"0")))))
  (check-true (do-not-track? (make-test-request #:headers (list (make-header #"DNT" #"1"))))))


(define (spammer? req)
  (with-handlers ([exn:fail? (const #f)])
    (and~>> (assq* 'ref (url-query (request-uri req)))
            (string->url)
            (url-host)
            (set-member? config:spammers))))

(module+ test
  (check-false (spammer? (make-test-request)))
  (check-false (spammer? (make-test-request #:query '((ref . "http://google.com")))))
  (check-false (spammer? (make-test-request #:query '((ref . "this-isnt-even-valid")))))
  (check-false (spammer? (make-test-request #:query '((ref . "dienai.ru")))))
  (check-true (spammer? (make-test-request #:query '((ref . "http://nizniynovgorod.dienai.ru"))))))


(define (request-proxied-ip req)
  (with-handlers ([exn:fail:contract? (const (request-client-ip req))]) ;; handle empty xff
    (or (and~> (headers-assq* #"x-forwarded-for" (request-headers/raw req))
               (header-value)
               (bytes->string/utf-8)
               (string-split _ "," #:repeat? #f)
               (car))
        (request-client-ip req))))

(module+ test
  (check-equal? (request-proxied-ip (make-test-request)) "127.0.0.1")
  (check-equal? (request-proxied-ip (make-test-request #:headers (list (make-header #"x-forwarded-for" #"80.97.145.32, 127.0.0.1")))) "80.97.145.32")
  (check-equal? (request-proxied-ip (make-test-request #:headers (list (make-header #"x-forwarded-for" #"")))) "127.0.0.1"))


(define (request->page-visit req)
  (with-handlers ([exn:fail? (lambda (e)
                               (raise (exn:bad-request
                                       "uid, sid, loc and cts parameters are required"
                                       (current-continuation-marks))))])
    (define query  (url-query (request-uri req)))
    (page-visit (assq* 'uid query)
                (assq* 'sid query)
                (string->url (assq* 'loc query))
                (and~> (assq* 'ref query) (string->url))
                (request-proxied-ip req))))

(module+ test
  (check-equal?
   (request->page-visit (make-test-request #:query '((uid . "1")
                                                     (sid . "2")
                                                     (loc . "http://example.com")
                                                     (ref . "http://google.com"))))
   (page-visit "1"
               "2"
               (string->url "http://example.com")
               (string->url "http://google.com")
               "127.0.0.1" )))
