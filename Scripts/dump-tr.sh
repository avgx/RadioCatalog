#!/bin/bash
set -e

echo "Downloading..."

wget \
  --recursive \
  --level=3 \
  --no-parent \
  --domains top-radio.ru \
  https://top-radio.ru
