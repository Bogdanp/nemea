#lang racket/base

(require koyo/http
         net/url
         racket/function
         racket/set
         racket/string
         threading
         web-server/http
         (prefix-in config: "../config.rkt")
         "../components/batcher.rkt"
         "../components/current-visitors.rkt"
         "../components/page-visit.rkt"
         "common.rkt"
         "middleware.rkt")

(provide
 track-page-visit)

;; This is on the "hot path" so it has no contract.
(define ((track-page-visit batcher current-visitors) req)
  (when (track? req)
    (define page-visit (request->page-visit req))
    (current-visitors-track current-visitors
                            (page-visit-unique-id page-visit)
                            (page-visit-location page-visit))
    (enqueue batcher page-visit))

  (response/output
   #:mime-type #"image/gif"
   (lambda (out)
     (display #"GIF89a\1\0\1\0\0\377\0,\0\0\0\0\1\0\1\0\0\2\0;" out))))

(define (track? req)
  (not (or (do-not-track? req)
           (spammer? req))))

(define (do-not-track? req)
  (and~> (headers-assq* #"DNT" (request-headers/raw req))
         (header-value)
         (bytes=? #"1")))

(define (spammer? req)
  (and~> (request-bindings/raw req)
         (bindings-ref 'ref)
         (string->url)
         (url-host)
         (set-member? config:spammers _)))

(define (request-proxied-ip req)
  (with-handlers ([exn:fail:contract? (const (request-client-ip req))]) ;; handle empty xff
    (or (and~> (headers-assq* #"x-forwarded-for" (request-headers/raw req))
               (header-value)
               (bytes->string/utf-8)
               (string-split _ "," #:repeat? #f)
               (car))
        (request-client-ip req))))

(define (request->page-visit req)
  (with-handlers ([exn:fail? (lambda (e)
                               (bad-request "uid, sid, loc and cts parameters are required"))])
    (define bindings (request-bindings/raw req))
    (page-visit (bindings-ref bindings 'uid)
                (bindings-ref bindings 'sid)
                (string->url (bindings-ref bindings 'loc))
                (cond
                  [(bindings-ref bindings 'ref) => string->url]
                  [else #f])
                (request-proxied-ip req))))

(module+ test
  (require koyo/testing
           rackunit
           rackunit/text-ui)

  (run-tests
   (test-suite
    "tracking"

    (test-suite
     "track?"

     (test-true
      "tracks empty requests"
      (track? (make-test-request)))

     (test-false
      "does not track requests with DNT headers"
      (track? (make-test-request #:headers (list (make-header #"DNT" #"1"))))))

    (test-suite
     "do-not-track?"

     (test-false
      "#f given an empty request"
      (do-not-track? (make-test-request)))

     (test-false
      "#f given a request with a falsy DNT header"
      (do-not-track? (make-test-request #:headers (list (make-header #"DNT" #"0")))))

     (test-true
      "#t given a request with a truthy DNT header"
      (do-not-track? (make-test-request #:headers (list (make-header #"DNT" #"1"))))))

    (test-suite
     "spammer?"

     (test-false
      "#f given an empty request"
      (spammer? (make-test-request)))

     (test-false
      "#f given a valid referrer"
      (spammer? (make-test-request #:query '((ref . "http://google.com")))))

     (test-false
      "#f given an invalid referrer URL"
      (spammer? (make-test-request #:query '((ref . "this-isnt-even-valid")))))

     (test-false
      "#f given a non-blacklisted URL"
      (spammer? (make-test-request #:query '((ref . "dienai.ru")))))

     (test-true
      "#t given a blacklisted URL"
      (spammer? (make-test-request #:query '((ref . "http://nizniynovgorod.dienai.ru"))))))

    (test-suite
     "request-proxied-ip"

     (test-equal?
      "same as client-ip when the request has no X-Forwarded-For header"
      (request-proxied-ip (make-test-request))
      "127.0.0.1")

     (test-equal?
      "same as the first IP in the list when the request has an X-Forwarded-For header"
      (request-proxied-ip (make-test-request #:headers (list (make-header #"x-forwarded-for" #"80.97.145.32, 127.0.0.1"))))
      "80.97.145.32")

     (test-equal?
      "same as client-ip when the X-Forwarded-For header is empty"
      (request-proxied-ip (make-test-request #:headers (list (make-header #"x-forwarded-for" #""))))
      "127.0.0.1"))

    (test-suite
     "request->page-visit"

     (test-equal?
      "converts a request to a page-visit as expected"
      (request->page-visit
       (make-test-request #:query '((uid . "1")
                                    (sid . "2")
                                    (loc . "http://example.com")
                                    (ref . "http://google.com"))))
      (page-visit "1"
                  "2"
                  (string->url "http://example.com")
                  (string->url "http://google.com")
                  "127.0.0.1" ))))))
