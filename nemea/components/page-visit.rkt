#lang racket/base

(require net/uri-codec
         net/url
         racket/contract
         racket/format
         racket/list
         racket/match
         racket/string)

(provide (contract-out
          [struct page-visit ((unique-id string?)
                              (session-id string?)
                              (location url?)
                              (referrer (or/c false/c url?))
                              (client-ip (or/c false/c string?)))]
          [url->canonical-host (-> url? string?)]
          [url->canonical-path (-> url? string?)]))

(struct page-visit
  (unique-id
   session-id
   location
   referrer
   client-ip)
  #:transparent)

(define (url->canonical-host url)
  (define host (url-host url))
  (define port (or (url-port url) 80))
  (cond
    [(= port 80) host]
    [(= port 443) host]
    [else (~a host ":" port)]))

(define (url->canonical-path url)
  (url-path->string (url-path url)))

(define (url-path->string url-path)
  (~a "/" (string-join (map path/param->string url-path) "/")))

(define (path/param->string path/param)
  (match (path/param-path path/param)
    ['up ".."]
    ['same "."]
    [path path]))


(module+ test
  (require rackunit)

  (check-equal? (url->canonical-host (string->url "http://example.com")) "example.com")
  (check-equal? (url->canonical-host (string->url "http://example.com:80")) "example.com")
  (check-equal? (url->canonical-host (string->url "https://example.com:443")) "example.com")
  (check-equal? (url->canonical-host (string->url "http://example.com:9000")) "example.com:9000")

  (check-equal? (url->canonical-path (string->url "http://example.com")) "/")
  (check-equal? (url->canonical-path (string->url "http://example.com/")) "/")
  (check-equal? (url->canonical-path (string->url "http://example.com/./../a")) "/./../a")
  (check-equal? (url->canonical-path (string->url "http://example.com/./../a/")) "/./../a/")
  (check-equal? (url->canonical-path (string->url "http://example.com/hello?")) "/hello")
  (check-equal? (url->canonical-path (string->url "http://example.com/hello?b=1&a")) "/hello")
  (check-equal? (url->canonical-path (string->url "http://example.com/hello?b=1&a#foo=1;bar")) "/hello"))
