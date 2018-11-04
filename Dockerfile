FROM node:10.6 AS assets

ADD . /opt/nemea
WORKDIR /opt/nemea
RUN npm install
RUN npx parcel build -d static assets/index.html
RUN npx parcel build -d static -o track.js --experimental-scope-hoisting assets/js/track.js

FROM python:3.7 AS asset_compression

ADD . /opt/nemea
WORKDIR /opt/nemea
COPY --from=assets /opt/nemea/static /opt/nemea/static
RUN pip install -U pip
RUN pip install whitenoise[brotli]
RUN python -m whitenoise.compress static

FROM jackfirth/racket:7.1

ADD . /opt/nemea
WORKDIR /opt/nemea
COPY --from=asset_compression /opt/nemea/static /opt/nemea/static
RUN raco pkg install --auto nemea/
RUN raco setup -D --tidy --check-pkg-deps --unused-pkg-deps --pkgs nemea
EXPOSE 8000

CMD ["racket", "-l", "nemea"]
