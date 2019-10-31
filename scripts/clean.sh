#!/usr/bin/env bash

set -euo pipefail

find nemea -type d -name compiled -exec rm -rf \{\} \;
rm -f static/*
