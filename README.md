# nemea

Take control of your website analytics!


## Developing

### Requirements

nemea is a [Racket] application so you'll need to install that and
you'll need [Node.js] version `10.6.0` to build the static assets.
Optionall, you'll need [Python] for the development process manager
(honcho).

You'll also need a running [PostgreSQL] instance.

### First-time setup

Install all the prerequisites:

    $ raco pkg install nemea/
    $ npm install
    $ pip install honcho
    $ cp .env.default .env.dev

Set up the databases:

    $ psql <<-SQL
    create user nemea with password 'nemea' login;
    create database nemea;
    grant all privileges on database nemea to nemea;
    create database nemea_tests;
    grant all privileges on database nemea_tests to nemea;
    SQL

### Running the development server

    $ honcho -e .env.dev -p 8000 -f Procfile.dev

### Running the tests

    $ raco test nemea/


## License

    dramatiq is licensed under the GPL. Please see COPYING for details.


[Racket]: https://racket-lang.org
[Python]: https://python.org
[Node.js]: https://nodejs.org
[PostgreSQL]: https://www.postgresql.org
