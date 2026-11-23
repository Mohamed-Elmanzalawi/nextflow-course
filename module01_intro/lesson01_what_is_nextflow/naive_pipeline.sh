#!/usr/bin/env bash
# A "classic" Bash pipeline: count reads per sample, then build a summary table.
set -euo pipefail

mkdir -p results

for fq in data/*.fastq; do
    sample=$(basename "$fq" .fastq)
    echo "[$(date +%T)] Processing $sample"
    sleep 2                                   # pretend this is a slow tool (e.g. an aligner)
    awk -v s="$sample" 'END{print s"\t"NR/4}' "$fq" > "results/${sample}.count.tsv"
done

cat results/*.count.tsv > results/summary.tsv
echo "[$(date +%T)] Done. Summary:"
cat results/summary.tsv
