#!/usr/bin/env bash
# Create test files for Lesson 2.1: a good gzipped FASTQ and a truncated (corrupt) one.
set -euo pipefail
mkdir -p data
awk 'BEGIN{
    srand(7);
    for (r = 1; r <= 1000; r++) {
        seq = ""; for (b = 1; b <= 50; b++) seq = seq substr("ACGT", int(rand()*4)+1, 1)
        print "@read" r; print seq; print "+"; print "IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"
    }
}' | gzip -c > data/good.fastq.gz
# A download that stopped early: keep only the first 40% of the compressed bytes
size=$(wc -c < data/good.fastq.gz | tr -d ' ')
head -c $(( size * 4 / 10 )) data/good.fastq.gz > data/truncated.fastq.gz
echo "Created data/good.fastq.gz (1000 reads) and data/truncated.fastq.gz (corrupt)"
