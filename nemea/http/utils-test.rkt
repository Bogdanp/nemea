#lang racket/base

(require net/url
         racket/contract
         racket/promise
         web-server/http)

(provide make-request)

(define/contract (make-request #:method [method "GET"]
                               #:path [path "/"]
                               #:headers [headers '()]
                               #:bindings [bindings '()]
                               #:content [content ""])
  (->* ()
       (#:method string?
        #:path string?
        #:headers (listof header?)
        #:bindings (listof binding?)
        #:content string?)
       request?)

  (request (string->bytes/utf-8 method)
           (string->url (format "http://example.com~a" path))
           headers (delay bindings)
           (string->bytes/utf-8 content)
           "127.0.0.1" 8000 "127.0.0.1"))
