#lang racket/base

(require net/url
         threading
         web-server/http
         "../components/batcher.rkt"
         "../components/page-visit.rkt"
         "middleware.rkt"
         "utils.rkt")

(provide track-page-visit)

;; This is on the "hot path" so it has no contract.
(define ((track-page-visit batcher) req)
  (unless (do-not-track? req)
    (enqueue batcher (request->page-visit req)))
  (response/pixel))


(define (do-not-track? req)
  (and~> (headers-assq* #"DNT" (request-headers/raw req))
         (header-value)
         (bytes=? #"1")))

(module+ test
  (require rackunit
           "utils-test.rkt")

  (check-false (do-not-track? (make-request)))
  (check-false (do-not-track? (make-request #:headers (list (make-header #"DNT" #"0")))))
  (check-true (do-not-track? (make-request #:headers (list (make-header #"DNT" #"1"))))))


(define (request->page-visit req)
  ;; TODO: Handle x-forwarded-for.
  (define client-ip (request-client-ip req))
  (define query  (url-query (request-uri req)))

  (with-handlers ([exn:fail? (lambda (e)
                               (raise (exn:bad-request
                                       "uid, sid, loc and cts parameters are required"
                                       (current-continuation-marks))))])
    (page-visit (assq* 'uid query)
                (assq* 'sid query)
                (string->url (assq* 'loc query))
                (and~> (assq* 'ref query) (string->url))
                client-ip)))

(module+ test
  (require rackunit
           "utils-test.rkt")

  (check-equal?
   (request->page-visit (make-request #:path "/?uid=1&sid=2&loc=http%3A%2F%2Fexample.com&ref=http%3A%2F%2Fgoogle.com"))
   (page-visit "1"
               "2"
               (string->url "http://example.com")
               (string->url "http://google.com")
               "127.0.0.1" )))
