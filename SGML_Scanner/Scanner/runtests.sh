#!/bin/bash

echo "=== CIS 4650 Scanner Test Script ==="
echo

for testfile in tests/*.sgml; do
    echo "Running test: $testfile"
    echo "--------------------------------"
    java Scanner < "$testfile"
    echo
done

echo "=== All tests completed ==="