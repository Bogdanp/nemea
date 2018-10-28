#lang racket/base

(require net/url
         threading
         web-server/http
         "../components/batcher.rkt"
         "../components/page-visits.rkt"
         "middleware.rkt"
         "utils.rkt")

(provide track-page-visit)

(define ((track-page-visit batcher) req)
  (enqueue batcher (~> (request-uri req)
                       (url-query)
                       (query->page-visit)))
  (response/pixel))

(define (query->page-visit query)
  (with-handlers ([exn:fail? (lambda (e)
                               (raise (exn:bad-request
                                       "loc and cts parameters are required"
                                       (current-continuation-marks))))])
    (page-visit (string->url (assq* 'loc query))
                (assq* 'cip query)
                (string->number (assq* 'cts query))
                (and~> (assq* 'cre query) (string->url)))))

(module+ test
  (require rackunit)

  (check-equal?
   (query->page-visit '((loc . "http://example.com")
                        (cip . "127.0.0.1")
                        (cts . "1540552567438")))
   (page-visit (string->url "http://example.com") "127.0.0.1" 1540552567438 #f)))
