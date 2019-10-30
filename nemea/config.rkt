#lang racket/base

(require (for-syntax racket/base)
         gregor
         koyo/config
         net/url
         racket/port
         racket/runtime-path
         racket/set
         racket/string)

(current-option-name-prefix "NEMEA")

(define-option hostname
  #:default "127.0.0.1")

(define-option host
  #:default "127.0.0.1")

(define-option port
  #:default "8000"
  (string->number port))

(define-option timezone
  #:default (current-timezone))

(define-option database-url
  #:default "postgres://nemea:nemea@127.0.0.1/nemea"
  (string->url database-url))

(define-syntax-rule (define/provide name e ...)
  (begin
    (define name e ...)
    (provide name)))

(define/provide db-username (car (string-split (url-user database-url) ":")))
(define/provide db-password (cadr (string-split (url-user database-url) ":")))
(define/provide db-host (url-host database-url))
(define/provide db-port (or (url-port database-url) 5432))
(define/provide db-name (path/param-path (car (url-path database-url))))

(define-option db-max-connections
  #:default "16"
  (string->number db-max-connections))

(define-option db-max-idle-connections
  #:default "2"
  (string->number db-max-idle-connections))

(define-option batcher-channel-size
  #:default "1000000"
  (string->number batcher-channel-size))

(define-option batcher-timeout
  #:default "5"
  (string->number batcher-timeout))

(define-option log-level
  #:default "info"
  (string->symbol log-level))

(define-runtime-path spammers-file-path (build-path 'up "assets" "data" "spammers.txt"))
(define/provide spammers
  (call-with-input-file spammers-file-path
    (lambda (in)
      (list->set
       (string-split (port->string in) "\n")))))
