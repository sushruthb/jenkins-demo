#!/bin/bash
set -e
echo "--- Lint: checking shell script syntax ---"
for f in *.sh; do
    bash -n "$f" && echo "OK: $f"
done
echo "--- Lint passed ---"
