#!/usr/bin/env bash
# Lesson 5.1 challenge checker: runs your fix_ref.nf on 4 fresh samples.
# Usage: bash check_fix_ref.sh [path/to/fix_ref.nf]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../tools/checklib.sh"
source "$HERE/../../tools/nflib.sh"
ID="5.1-challenge"
SCRIPT="${1:-$HERE/fix_ref.nf}"

echo "Checking $SCRIPT"
if ! nf_have; then fail "Nextflow is installed" "install it first (Lesson 2.2)"; finish "$ID"; exit 1; fi
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$SCRIPT" "$TMP/fix_ref.nf" 2>/dev/null || { fail "fix_ref.nf exists" "not found: $SCRIPT"; finish "$ID"; exit 1; }
cp "$HERE/ref.fa" "$TMP/genome.fa"
bash "$HERE/../fresh_reads.sh" "$TMP/fresh" s1=cov_a s2=cov_b s3=hsa_rna s4=cov_a

if (cd "$TMP" && nextflow lint fix_ref.nf > lint.log 2>&1); then
    pass "fix_ref.nf passes 'nextflow lint'"
else
    fail "fix_ref.nf passes 'nextflow lint'" "$(grep -m1 -E '^Error' "$TMP/lint.log")"
fi

if nf_run "$TMP" trace.tsv fix_ref.nf --reads 'fresh/*_R1.fastq.gz' --reference genome.fa --adapter CTGTCTCTTATA; then
    pass "Runs with --reads, --reference and --adapter"
else
    fail "Runs with --reads, --reference and --adapter" "$(nf_error "$TMP")"
fi

n=$(nf_count "$TMP/trace.tsv" TRIM_AND_MAP COMPLETED)
if [[ "$n" == 4 ]]; then
    pass "TRIM_AND_MAP runs for every sample" "4 tasks"
else
    fail "TRIM_AND_MAP runs for every sample" "$n task(s) for 4 samples: a single-item queue channel is still being used up"
fi

want=$(printf '%s\n' "s1_R1: 100 reads, adapter CTGTCTCTTATA, reference genome.fa" \
    "s2_R1: 100 reads, adapter CTGTCTCTTATA, reference genome.fa" \
    "s3_R1: 4159 reads, adapter CTGTCTCTTATA, reference genome.fa" \
    "s4_R1: 100 reads, adapter CTGTCTCTTATA, reference genome.fa")
got=$(cat "$(find "$TMP/work" -name summary.txt -type f 2>/dev/null | head -n 1)" 2>/dev/null)
if [[ "$got" == "$want" ]]; then
    pass "summary.txt has all 4 samples, each with the reference and adapter"
else
    fail "summary.txt has all 4 samples, each with the reference and adapter" "got $(grep -c . <<< "$got") line(s)"
fi
finish "$ID"
