#lang info

(define collection "nemea")
(define deps '("base"
               "chief"
               "component-lib"
               "db-lib"
               "geoip-lib"
               "gregor-lib"
               "https://github.com/Bogdanp/koyo.git?path=koyo-lib"
               "retry"
               "sql"
               "threading-lib"
               "web-server-lib"))
(define build-deps '("rackunit-lib"))
