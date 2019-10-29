#lang racket/base

(require koyo/json)

(provide
 bad-request
 exn:bad-request?
 wrap-custom-exns)

(define-logger http-error)

(struct exn:bad-request exn:fail ())

(define (bad-request message . args)
  (raise (exn:bad-request (format message args) (current-continuation-marks))))

(define (bad-request->response e)
  (log-http-error-warning "encountered bad request: ~a" (exn-message e))
  (response/json
   #:code 400
   (hasheq 'error (exn-message e))))

(define (internal-error->response e)
  (log-http-error-error "unhandled error: ~a" (exn-message e))
  (response/json
   #:code 500
   (hasheq 'error "internal server error")))

(define ((wrap-custom-exns app) req)
  (with-handlers ([exn:bad-request? bad-request->response]
                  [exn:fail? internal-error->response])
    (app req)))
