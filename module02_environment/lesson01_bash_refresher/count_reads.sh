#!/usr/bin/env bash
# Count the reads in a gzipped FASTQ file.  Usage: bash count_reads.sh file.fastq.gz
# (This version has a hidden bug. Can you spot it?)
set -eu

gzip -dc "$1" | awk 'END{print NR/4}'
