#!/usr/bin/env bash
# Create the two small input tables for Lesson 1.2.
set -euo pipefail
mkdir -p data
# Expression counts from your lab (unsorted, as they come out of the counting tool)
printf '%s\t%s\n' Tp53 120 egfr 45 ACTB 980 Gapdh 870 MYC 230 BRCA1 15 > data/expression.tsv
# Gene annotation from a shared reference folder, already sorted on the cluster with LC_ALL=C
printf '%s\t%s\n' ACTB chr7 BRCA1 chr17 Gapdh chr12 MYC chr8 Tp53 chr17 egfr chr7 | LC_ALL=C sort > data/annotation.tsv
echo "Created data/expression.tsv (6 genes) and data/annotation.tsv (6 genes)"
