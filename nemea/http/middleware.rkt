#lang racket/base

(require "utils.rkt")

(provide (struct-out exn:bad-request)
         wrap-custom-exns)

(define-logger http-error)

(struct exn:bad-request exn:fail ())

(define (bad-request->response e)
  (log-http-error-warning "encountered bad request: ~a" (exn-message e))
  (response/json #:body (hasheq 'error (exn-message e))
                 #:code 400))

(define (internal-error->response e)
  (log-http-error-error "unhandled error: ~a" (exn-message e))
  (response/json #:body (hasheq 'error "internal server error")
                 #:code 500))

(define ((wrap-custom-exns app) req)
  (with-handlers ([exn:bad-request? bad-request->response]
                  [exn:fail? internal-error->response])
    (app req)))
