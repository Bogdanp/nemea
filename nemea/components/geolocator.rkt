#lang racket/base

(require (for-syntax racket/base)
         component
         geoip
         racket/contract
         racket/runtime-path
         threading)

(provide
 make-geolocator
 geolocator?
 geolocator-country-code)

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

(define/contract (geolocator-country-code geolocator ip)
  (-> geolocator? string? (or/c false/c string?))
  (and~> (geoip-lookup (geolocator-db geolocator) ip)
         (hash-ref "country" #f)
         (hash-ref "iso_code" #f)))

(module+ test
  (require rackunit
           rackunit/text-ui)

  (define geolocator (component-start (make-geolocator)))

  (run-tests
   (test-suite
    "geolocator"

    (test-suite
     "geolocator-country-code"

     (test-false
      "#f when given a private IP"
      (geolocator-country-code geolocator "127.0.0.1"))

     (test-equal?
      "returns the country code when given a public IP"
      (geolocator-country-code geolocator "188.24.7.80")
      "RO")))))
