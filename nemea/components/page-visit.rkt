#lang racket/base

(require net/uri-codec
         net/url
         racket/contract
         racket/format
         racket/match
         racket/string)

(provide
 (contract-out
  [struct page-visit ([unique-id string?]
                      [session-id string?]
                      [location url?]
                      [referrer (or/c false/c url?)]
                      [client-ip (or/c false/c string?)])]
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
    [(= port 80)  host]
    [(= port 443) host]
    [else (~a host ":" port)]))

(define (url->canonical-path url)
  (define path (url-path->string (url-path url)))
  (define query (query->string (url-query url)))
  (define fragment (fragment->string (url-fragment url)))
  (~a path query fragment))

(define (url-path->string url-path)
  (~a "/" (string-join (map path/param->string url-path) "/")))

(define (path/param->string path/param)
  (match (path/param-path path/param)
    ['same "."]
    ['up   ".."]
    [path  path]))

(define (query->string query)
  (define params
    (for/list ([pair query])
      (match pair
        [(cons name #f)    (~a (uri-encode (symbol->string name)) "=")]
        [(cons name value) (~a (uri-encode (symbol->string name)) "=" (uri-encode value))])))

  (cond
    [(null? params) ""]
    [else (~a "?" (string-join (sort params string<?) "&"))]))

(define (fragment->string fragment)
  (if fragment (~a "#" fragment) ""))


(module+ test
  (require rackunit
           rackunit/text-ui)

  (run-tests
   (test-suite
    "page-visit"

    (test-suite
     "url->canonical-host"
     (check-equal? (url->canonical-host (string->url "http://example.com")) "example.com")
     (check-equal? (url->canonical-host (string->url "http://example.com:80")) "example.com")
     (check-equal? (url->canonical-host (string->url "https://example.com:443")) "example.com")
     (check-equal? (url->canonical-host (string->url "http://example.com:9000")) "example.com:9000"))

    (test-suite
     "url->canonical-path"

     (check-equal? (url->canonical-path (string->url "http://example.com")) "/")
     (check-equal? (url->canonical-path (string->url "http://example.com/")) "/")
     (check-equal? (url->canonical-path (string->url "http://example.com/./../a")) "/./../a")
     (check-equal? (url->canonical-path (string->url "http://example.com/./../a/")) "/./../a/")
     (check-equal? (url->canonical-path (string->url "http://example.com/hello?")) "/hello")
     (check-equal? (url->canonical-path (string->url "http://example.com/hello?b=1&a")) "/hello?a=&b=1")
     (check-equal? (url->canonical-path (string->url "http://example.com/hello?b=1&a#foo=1;bar")) "/hello?a=&b=1#foo=1;bar")))))
