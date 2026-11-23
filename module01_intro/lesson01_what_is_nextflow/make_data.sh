#!/usr/bin/env bash
# Create tiny fake FASTQ files for Lesson 1.1.
# Usage: bash make_data.sh [n_samples] [reads_per_sample]
set -euo pipefail
n_samples=${1:-3}
n_reads=${2:-1000}
mkdir -p data
for i in $(seq 1 "$n_samples"); do
    awk -v n="$n_reads" -v s="sample$i" 'BEGIN{
        srand(42);
        for (r = 1; r <= n; r++) {
            seq = ""; qual = "";
            for (b = 1; b <= 50; b++) { seq = seq substr("ACGT", int(rand()*4)+1, 1); qual = qual "I" }
            print "@" s "_read" r; print seq; print "+"; print qual
        }
    }' > "data/sample${i}.fastq"
done
echo "Created $n_samples FASTQ files with $n_reads reads each in data/"
