#!/usr/bin/env bash

set -euo pipefail

log() {
    printf "[%s] %s\\n" "$(date)" "$@"
}

log "Cleaning static/ dir."
rm static/*

log "Building UI..."
npx parcel build -d static assets/index.html

log "Building track.js..."
npx parcel build -d static -o track.js --experimental-scope-hoisting assets/js/track.js

log "Compressing static assets..."
python -m whitenoise.compress static

log "Compiling Racket sources..."
raco setup --tidy --check-pkg-deps --unused-pkg-deps --pkgs nemea
