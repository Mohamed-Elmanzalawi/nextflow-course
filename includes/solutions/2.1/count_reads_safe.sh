#!/usr/bin/env bash
# Reference solution for the Lesson 2.1 challenge.
# Count the reads in a gzipped FASTQ file.  Usage: bash count_reads_safe.sh file.fastq.gz
set -euo pipefail        # pipefail: a failure ANYWHERE in a pipe fails the whole pipe

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 file.fastq.gz" >&2          # messages go to stderr (>&2)
    exit 2
fi
if [[ ! -r "$1" ]]; then
    echo "Error: cannot read '$1'" >&2
    exit 3
fi

# Capture the count first, so nothing is printed if gzip fails halfway.
count=$(gzip -dc "$1" | awk 'END{print NR/4}')
echo "$count"
