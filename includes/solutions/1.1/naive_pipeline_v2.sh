#!/usr/bin/env bash
# Reference solution for the Lesson 1.1 challenge:
# parallel samples + skip finished work on a rerun.
set -euo pipefail

mkdir -p results

process_sample() {
    local fq=$1 sample out
    sample=$(basename "$fq" .fastq)
    out="results/${sample}.count.tsv"

    if [[ -s "$out" ]]; then                 # finished on an earlier run
        echo "[$(date +%T)] Skipping $sample (already done)"
        return 0
    fi

    echo "[$(date +%T)] Processing $sample"
    sleep 2                                  # the "slow tool"
    # Write to a temporary file, then rename it. A rename is atomic, so an
    # interrupted run can never leave a half-written result that looks finished.
    awk -v s="$sample" 'END{print s"\t"NR/4}' "$fq" > "${out}.tmp"
    mv "${out}.tmp" "$out"
}

pids=()
for fq in data/*.fastq; do
    process_sample "$fq" &                   # run each sample in the background
    pids+=("$!")
done

# A bare `wait` always returns 0 and would hide failed samples,
# so wait for each job and remember whether any of them failed.
failed=0
for pid in "${pids[@]}"; do
    wait "$pid" || failed=1
done
if (( failed )); then
    echo "Some samples failed; not writing the summary." >&2
    exit 1
fi

cat results/*.count.tsv > results/summary.tsv
echo "[$(date +%T)] Done. Summary:"
cat results/summary.tsv
