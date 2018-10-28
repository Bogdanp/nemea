# nemea

Take control of your website analytics!


## Developing

### Requirements

nemea is a [Racket] application so you'll need to install that and
you'll need [Node.js] version `10.6.0` to build the static assets.
Additionally, you'll need [Python] for the development process
manager.

### First-time setup

    $ raco install nemea/
    $ npm install
    $ pip install honcho
    $ cp .env.default .env.dev

### Running the development server

    $ honcho -e .env.dev -p 8000 -f Procfile.dev


[Racket]: https://racket-lang.org
[Python]: https://python.org
[Node.js]: https://nodejs.org


## License

    dramatiq is licensed under the GPL. Please see COPYING for details.
