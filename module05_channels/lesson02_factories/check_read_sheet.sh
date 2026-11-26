#!/usr/bin/env bash
# Lesson 5.2 challenge checker: runs your read_sheet.nf on a new samplesheet, then on one with a missing file.
# Usage: bash check_read_sheet.sh [path/to/read_sheet.nf]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../tools/checklib.sh"
source "$HERE/../../tools/nflib.sh"
ID="5.2-challenge"
SCRIPT="${1:-$HERE/read_sheet.nf}"

echo "Checking $SCRIPT"
if ! nf_have; then fail "Nextflow is installed" "install it first (Lesson 2.2)"; finish "$ID"; exit 1; fi
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$SCRIPT" "$TMP/read_sheet.nf" 2>/dev/null || { fail "read_sheet.nf exists" "not found: $SCRIPT"; finish "$ID"; exit 1; }
# File names that a glob like *_R{1,2} would NOT pair up: only the samplesheet knows what belongs together
bash "$HERE/../fresh_reads.sh" "$TMP/raw" p1=cov_b p2=hsa_rna
mkdir -p "$TMP/run_07"
mv "$TMP/raw/p1_R1.fastq.gz" "$TMP/run_07/lane1_forward.fq.gz"; mv "$TMP/raw/p1_R2.fastq.gz" "$TMP/run_07/lane1_reverse.fq.gz"
mv "$TMP/raw/p2_R1.fastq.gz" "$TMP/run_07/lane2_forward.fq.gz"; mv "$TMP/raw/p2_R2.fastq.gz" "$TMP/run_07/lane2_reverse.fq.gz"
printf 'sample,fastq_1,fastq_2\nPAT001,run_07/lane1_forward.fq.gz,run_07/lane1_reverse.fq.gz\nPAT002,run_07/lane2_forward.fq.gz,run_07/lane2_reverse.fq.gz\n' > "$TMP/good.csv"
printf 'sample,fastq_1,fastq_2\nPAT001,run_07/lane1_forward.fq.gz,run_07/lane1_reverse.fq.gz\nPAT003,run_07/lane3_forward.fq.gz,run_07/lane3_reverse.fq.gz\n' > "$TMP/missing.csv"

if (cd "$TMP" && nextflow lint read_sheet.nf > lint.log 2>&1); then
    pass "read_sheet.nf passes 'nextflow lint'"
else
    fail "read_sheet.nf passes 'nextflow lint'" "$(grep -m1 -E '^Error' "$TMP/lint.log")"
fi

nf_run "$TMP" trace.tsv read_sheet.nf --input good.csv
n=$(nf_count "$TMP/trace.tsv" COUNT_PAIRS COMPLETED)
if [[ "$n" == 2 ]]; then
    pass "One COUNT_PAIRS task per samplesheet row" "2 tasks"
else
    fail "One COUNT_PAIRS task per samplesheet row" "found $n, expected 2 $(nf_error "$TMP")"
fi

want=$(printf 'PAT001\t100\t100\nPAT002\t4159\t4159')
got=$(cat "$(find "$TMP/work" -name pairs_report.tsv -type f 2>/dev/null | head -n 1)" 2>/dev/null)
if [[ "$got" == "$want" ]]; then
    pass "pairs_report.tsv pairs each sample with its own R1 and R2"
else
    fail "pairs_report.tsv pairs each sample with its own R1 and R2" "got: $(tr '\t\n' ' ;' <<< "$got")"
fi

mkdir -p "$TMP/m" && cp "$TMP/read_sheet.nf" "$TMP/missing.csv" "$TMP/m/" && cp -R "$TMP/run_07" "$TMP/m/"
nf_run "$TMP/m" trace.tsv read_sheet.nf --input missing.csv
status=$?
if [[ "$status" != 0 ]] && grep -q 'lane3_forward.fq.gz' "$TMP/m/run.log"; then
    pass "A missing file stops the run, and the error names it"
else
    fail "A missing file stops the run, and the error names it" "exit=$status; use checkIfExists"
fi
finish "$ID"
