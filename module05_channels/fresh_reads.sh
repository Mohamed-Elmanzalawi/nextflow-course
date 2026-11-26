#!/usr/bin/env bash
# Used by the Module 5 checkers: make fresh, renamed copies of the course data.
# Usage: bash fresh_reads.sh <out_dir> <new_name>=<old_name> ...   (old: cov_a, cov_b, hsa_rna)
# Copies <old>_R1/_R2.fastq.gz to <out_dir>/<new>_R1/_R2.fastq.gz; downloads the data first if needed.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out=$1; shift
cache="$HERE/data"
if [[ ! -f "$cache/hsa_rna_R2.fastq.gz" ]]; then bash "$HERE/get_data.sh" "$cache" > /dev/null; fi
mkdir -p "$out"
for pair in "$@"; do
    new=${pair%%=*}; old=${pair#*=}
    cp "$cache/${old}_R1.fastq.gz" "$out/${new}_R1.fastq.gz"
    cp "$cache/${old}_R2.fastq.gz" "$out/${new}_R2.fastq.gz"
done
