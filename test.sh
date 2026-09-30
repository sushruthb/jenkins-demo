#!/bin/bash
set -e

echo "--- Test 1: hello.sh exits with code 0 ---"
bash hello.sh > /dev/null 2>&1
echo "PASS: hello.sh runs without errors"

echo "--- Test 2: output.txt exists ---"
if [ ! -f output.txt ]; then
    echo "FAIL: output.txt not found"
    exit 1
fi
echo "PASS: output.txt exists"

echo "--- Test 3: output.txt contains a username ---"
if ! grep -q "$(whoami)" output.txt; then
    echo "FAIL: output.txt does not contain expected username"
    exit 1
fi
echo "PASS: output.txt contains expected username"

echo "--- Test 4: APP_ENV is set ---"
if [ -z "${APP_ENV}" ]; then
    echo "FAIL: APP_ENV is not set"
    exit 1
fi
echo "PASS: APP_ENV is set to '${APP_ENV}'"

echo "--- All tests passed ---"
