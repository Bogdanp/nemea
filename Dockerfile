FROM node:10.6 AS assets

ADD . /opt/nemea
WORKDIR /opt/nemea
RUN npm install \
  && npx parcel build -d static assets/index.html \
  && npx parcel build -d static -o track.js --experimental-scope-hoisting assets/js/track.js

FROM python:3.7 AS asset_compression

ADD . /opt/nemea
WORKDIR /opt/nemea
COPY --from=assets /opt/nemea/static /opt/nemea/static
RUN pip install -U pip \
  && pip install whitenoise[brotli] \
  && python -m whitenoise.compress static

FROM jackfirth/racket:7.1 AS distribution

ADD . /opt/nemea
WORKDIR /opt/nemea
COPY --from=asset_compression /opt/nemea/static /opt/nemea/static
RUN raco pkg install --auto nemea/ \
  && raco setup -D --tidy --check-pkg-deps --unused-pkg-deps --pkgs nemea \
  && raco exe -o nemea.bin nemea/main.rkt \
  && raco distribute dist nemea.bin

FROM debian

COPY --from=distribution /opt/nemea/dist /opt/nemea
WORKDIR /opt/nemea
EXPOSE 8000

CMD ["/opt/nemea/bin/nemea.bin"]
