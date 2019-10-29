#lang info

(define collection "nemea")
(define deps '("base"
               "chief"
               "component-lib"
               "db-lib"
               "geoip-lib"
               "gregor-lib"
               "koyo-lib"
               "retry"
               "sql"
               "threading-lib"
               "https://github.com/racket/web-server.git?path=web-server-lib"))
(define build-deps '("at-exp-lib"
                     "rackunit-lib"))
