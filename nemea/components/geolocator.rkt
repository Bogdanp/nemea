#lang racket/base

(require component
         geoip
         (for-syntax racket/base)
         racket/contract/base
         racket/runtime-path
         threading)

(provide (contract-out
          [struct geolocator ([db (or/c false/c geoip?)])]
          [make-geolocator (-> geolocator?)]
          [geolocator-country-code (-> geolocator? string? (or/c false/c string?))]))

(define-runtime-path DB-PATH
  (build-path 'up 'up "assets" "data" "GeoLite2-Country.mmdb"))

(struct geolocator (db)
  #:methods gen:component
  [(define (component-start a-geolocator)
     (struct-copy geolocator a-geolocator [db (make-geoip DB-PATH)]))

   (define (component-stop a-geolocator)
     (struct-copy geolocator a-geolocator [db #f]))])

(define (make-geolocator)
  (geolocator #f))

(define (geolocator-country-code geolocator ip)
  (and~> (geoip-lookup (geolocator-db geolocator) ip)
         (hash-ref "country")
         (hash-ref "iso_code")))

(module+ test
  (require rackunit)

  (define geolocator (component-start (make-geolocator)))
  (check-false (geolocator-country-code geolocator "127.0.0.1"))
  (check-equal? (geolocator-country-code geolocator "188.24.7.80") "RO"))
