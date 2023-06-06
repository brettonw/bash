#! /usr/bin/env bash

echo "{";
git for-each-ref --format='%(authorname)' | awk -v q="\"" -v c=": " -v m="," '{print q tolower($0) q c q $0 q m}' | sort | uniq;
echo "}";
