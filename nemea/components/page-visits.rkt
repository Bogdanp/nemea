#lang racket/base

(require net/url
         racket/contract)

(provide (contract-out
          (struct page-visit ((location url?)
                              (client-ip (or/c false/c string?))
                              (client-timestamp exact-positive-integer?)
                              (client-referrer (or/c false/c url?))))))

(struct page-visit
  (location
   client-ip
   client-timestamp
   client-referrer)
  #:transparent)
