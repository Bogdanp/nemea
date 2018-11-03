#!/usr/bin/env bash

set -euo pipefail

find nemea -type d -name compiled | xargs rm -rf
rm -f static/*
