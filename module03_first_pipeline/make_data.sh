#!/usr/bin/env bash
# Create small fake FASTQ files for Module 3.
# Every sample gets its own read count and GC content, so results differ per sample.
# Files that already exist are left untouched (same content, same timestamp).
# Usage: bash make_data.sh [n_samples] [base_reads] [out_dir]
set -euo pipefail
n_samples=${1:-3}
base_reads=${2:-1000}
out_dir=${3:-data}
mkdir -p "$out_dir"
made=0; kept=0
for i in $(seq 1 "$n_samples"); do
    if [[ -e "${out_dir}/sample${i}.fastq" ]]; then kept=$((kept + 1)); continue; fi
    made=$((made + 1))
    n_reads=$(( base_reads + 250 * (i - 1) ))
    awk -v n="$n_reads" -v s="sample$i" -v seed="$i" 'BEGIN{
        srand(seed);
        gc = 0.30 + 0.05 * ((seed - 1) % 6);      # 30%, 35%, 40% ... GC
        for (r = 1; r <= n; r++) {
            seq = ""; qual = "";
            for (b = 1; b <= 50; b++) {
                x = rand();
                if (x < gc / 2)      base = "G";
                else if (x < gc)     base = "C";
                else if (x < gc + (1 - gc) / 2) base = "A";
                else                 base = "T";
                seq = seq base; qual = qual "I";
            }
            print "@" s "_read" r; print seq; print "+"; print qual
        }
    }' > "${out_dir}/sample${i}.fastq"
done
echo "Created $made new FASTQ file(s) in ${out_dir}/ (kept $kept existing)"
