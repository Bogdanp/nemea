#lang racket/base

(require gregor
         net/url
         racket/string)

(provide (all-defined-out))

(define hostname (or (getenv "NEMEA_HOSTNAME") "127.0.0.1"))

(define listen-ip (or (getenv "NEMEA_LISTEN_IP") "127.0.0.1"))
(define port (string->number (or (getenv "PORT") "8000")))

(define timezone (or (getenv "NEMEA_TIMEZONE") (current-timezone)))

(define db-url (string->url (or (getenv "DATABASE_URL") "postgres://nemea:nemea@127.0.0.1/nemea")))
(define db-username (car (string-split (url-user db-url) ":")))
(define db-password (cadr (string-split (url-user db-url) ":")))
(define db-host (url-host db-url))
(define db-port (or (url-port db-url) 5432))
(define db-name (path/param-path (car (url-path db-url))))

(define db-max-connections (string->number (or (getenv "NEMEA_DB_MAX_CONNECTIONS") "4")))
(define db-max-idle-connections (string->number (or (getenv "NEMEA_DB_MAX_IDLE_CONNECTIONS") "1")))

(define batcher-channel-size (string->number (or (getenv "NEMEA_BATCHER_CHANNEL_SIZE") "1000000")))
(define batcher-timeout (string->number (or (getenv "NEMEA_BATCHER_TIMEOUT") "30")))

(define log-level (string->symbol (or (getenv "NEMEA_LOG_LEVEL") "info")))
