#lang at-exp racket/base

(require koyo/json
         racket/contract
         web-server/http)

(provide
 response/bad-request)

(define/contract (response/bad-request message)
  (-> string? response?)
  (response/json #:code 400 (hasheq 'error message)))
