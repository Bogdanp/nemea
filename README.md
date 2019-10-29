# nemea

Take control of your website analytics!

![screenshot](assets/img/screenshot.png)

## Developing

### Requirements

nemea is a [Racket] application so you'll need to install that and
you'll need [Node.js] version `10.6.0` to build the static assets.

You'll also need a running [PostgreSQL] instance.

### First-time setup

Install all the prerequisites:

    $ raco pkg install nemea/
    $ npm install
    $ cp .env.default .env

Set up the databases:

    $ psql <<-SQL
    create user nemea with password 'nemea' login;
    create database nemea;
    grant all privileges on database nemea to nemea;
    create database nemea_tests;
    grant all privileges on database nemea_tests to nemea;
    SQL
    $ echo "create extension if not exists hll;" | psql -Unemea -dnemea
    $ echo "create extension if not exists hll;" | psql -Unemea -dnemea_tests

### Running the development server

    $ raco chief start

### Running the tests

    $ raco test nemea/


## License

    nemea is licensed under the GPL. Please see COPYING for details.


[Racket]: https://racket-lang.org
[Node.js]: https://nodejs.org
[PostgreSQL]: https://www.postgresql.org
