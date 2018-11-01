#lang racket/base

(require net/url
         racket/contract)

(provide (contract-out
          [struct page-visit ((unique-id string?)
                              (session-id string?)
                              (location url?)
                              (client-referrer (or/c false/c url?))
                              (client-ip (or/c false/c string?)))]))

(struct page-visit
  (unique-id
   session-id
   location
   client-referrer
   client-ip)
  #:transparent)
