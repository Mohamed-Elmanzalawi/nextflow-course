#!/usr/bin/env bash
# Reference solution for the Lesson 1.2 challenge.
set -euo pipefail

# Pin the locale *inside* the script, so the result no longer depends on
# whoever runs it. C (byte order) is also how annotation.tsv was sorted.
export LC_ALL=C

mkdir -p results
sort data/expression.tsv > results/expression.sorted.tsv
join -t $'\t' results/expression.sorted.tsv data/annotation.tsv > results/annotated.tsv

echo "Annotated $(wc -l < results/annotated.tsv | tr -d ' ') of $(wc -l < data/expression.tsv | tr -d ' ') genes:"
cat results/annotated.tsv
