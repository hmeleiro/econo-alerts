#!/bin/bash
set -e  # exit on error
for f in scrapers/*.R; do
  # echo "Running $f"
  Rscript "$f"
done