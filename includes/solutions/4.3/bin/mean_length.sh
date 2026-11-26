#!/usr/bin/env bash
# Usage: mean_length.sh reads.fastq.gz   ->   prints: <sample><TAB><mean read length>
set -euo pipefail
f=$1
s=$(basename "$f" .fastq.gz)
gzip -cd "$f" | awk -v s="$s" 'NR % 4 == 2 { n++; total += length($0) }
    END { printf "%s\t%.1f\n", s, total / n }'
