#lang at-exp racket/base

(require json
         racket/contract
         racket/format
         racket/function
         racket/port
         threading
         web-server/http)

(provide assq*

         request/json
         response/json
         response/pixel)

(define (assq* k xs)
  (and~> (assq k xs) (cdr)))

(define STATUS-LINES-BY-CODE
  #hasheq((200 . #"OK")
          (201 . #"Created")
          (202 . #"Accepted")
          (400 . #"Bad Request")
          (404 . #"Not Found")
          (500 . #"Internal Server Error")))

(define (code->status-line code)
  (hash-ref STATUS-LINES-BY-CODE code))


(define/contract (request/json req)
  (-> request? (or/c false/c jsexpr?))
  (with-handlers ([exn:fail? (const #f)])
    (and~> (request-post-data/raw req)
           (bytes->jsexpr))))

(module+ test
  (require rackunit
           "utils-test.rkt")

  (check-equal?
   (request/json (make-request #:content "invalid"))
   #f)

  (check-equal?
   (request/json (make-request #:content "{\"x\": 42}"))
   #hasheq((x . 42))))


(define/contract (response/json #:body [body (make-immutable-hash)]
                                #:code [code 200]
                                #:headers [headers '()])
  (->* ()
       (#:body jsexpr?
        #:code exact-positive-integer?
        #:headers (listof header?))
       response?)

  (response/full
   code (code->status-line code)
   (current-seconds) #"application/json; charset=utf-8"
   headers (list (jsexpr->bytes body))))

(module+ test
  (require rackunit)

  (define a-response (response/json #:body "hi!"
                                    #:code 201
                                    #:headers (list (make-header #"x-some-header" #"val"))))
  (check-equal? (response-code a-response) 201)
  (check-equal? (headers-assq* #"x-some-header" (response-headers a-response)) (header #"x-some-header" #"val"))
  (check-equal? (call-with-output-string (response-output a-response)) @~a{"hi!"}))


(define GIF-MIME-TYPE #"image/gif")
(define PIXEL-BYTES #"GIF89a\1\0\1\0\0\377\0,\0\0\0\0\1\0\1\0\0\2\0;")
(define (response/pixel)
  (response/full 200 #"OK" (current-seconds) GIF-MIME-TYPE '() (list PIXEL-BYTES)))
