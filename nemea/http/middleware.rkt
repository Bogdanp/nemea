#lang racket/base

(require "utils.rkt")

(provide (struct-out exn:bad-request)
         handle-custom-exns)

(struct exn:bad-request exn:fail ())

(define (bad-request->response e)
  (log-warning "Encountered bad request: ~a" (exn-message e))
  (response/json #:body (hasheq 'error (exn-message e))
                 #:code 400))

(define (internal-error->response e)
  (log-error "Unhandled error: ~a" (exn-message e))
  (response/json #:body (hasheq 'error "internal server error")
                 #:code 500))

(define ((handle-custom-exns app) req)
  (with-handlers ([exn:bad-request? bad-request->response]
                  [exn:fail? internal-error->response])
    (app req)))
