#!/usr/bin/env bash
# Add a chromosome column to the expression table.
# `join` needs both inputs sorted the same way. annotation.tsv is pre-sorted, so we only sort ours.
set -euo pipefail

mkdir -p results
sort data/expression.tsv > results/expression.sorted.tsv
join -t $'\t' results/expression.sorted.tsv data/annotation.tsv > results/annotated.tsv

echo "Annotated $(wc -l < results/annotated.tsv | tr -d ' ') of $(wc -l < data/expression.tsv | tr -d ' ') genes:"
cat results/annotated.tsv
