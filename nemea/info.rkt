#lang info

(define collection "nemea")
(define deps '("base"
               "component-lib"
               "db-lib"
               "gregor-lib"
               "sql"
               "threading-lib"
               "https://github.com/racket/web-server.git?path=web-server-lib"))
(define build-deps '("at-exp-lib"
                     "rackunit-lib"))
