#!/usr/bin/env bash
# Lesson 3.4 challenge checker: runs your resume.nf three times and reads the trace each time.
# Usage: bash check_resume.sh [path/to/resume.nf]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../tools/checklib.sh"
source "$HERE/../../tools/nflib.sh"
ID="3.4-challenge"
SCRIPT="${1:-$HERE/resume.nf}"

echo "Checking $SCRIPT"
if ! nf_have; then
    fail "Nextflow is installed" "install it first (Lesson 2.2)"
    finish "$ID"; exit 1
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$SCRIPT" "$TMP/resume.nf" 2>/dev/null || { fail "resume.nf exists" "copy main.nf to resume.nf first"; finish "$ID"; exit 1; }
bash "$HERE/../make_data.sh" 3 300 "$TMP/data" > /dev/null

# Run 1: fresh
if nf_run "$TMP" trace1.tsv resume.nf; then
    pass "First run completes"
else
    fail "First run completes" "$(nf_error "$TMP")"
fi

S="$TMP/results/summary.tsv"
expected=$(printf 'sample\treads\n'; for f in "$TMP"/data/*.fastq; do
    awk -v s="$(basename "$f" .fastq)" 'END { print s "\t" NR / 4 }' "$f"; done | sort)
if [[ -f "$S" && "$(cat "$S")" == "$expected" ]]; then
    pass "summary.tsv starts with a 'sample<TAB>reads' header"
else
    fail "summary.tsv starts with a 'sample<TAB>reads' header" "first line: $(head -n 1 "$S" 2>/dev/null | tr '\t' '→')"
fi

# Run 2: touch every input (new timestamps, same content), then resume
sleep 1; touch "$TMP"/data/*.fastq
nf_run "$TMP" trace2.tsv resume.nf -resume
c=$(nf_count "$TMP/trace2.tsv" COUNT_READS CACHED)
if [[ "$c" == 3 ]]; then
    pass "After 'touch', -resume still caches all 3 COUNT_READS tasks"
else
    fail "After 'touch', -resume still caches all 3 COUNT_READS tasks" "cached $c of 3: new timestamps changed the hash"
fi

# Run 3: one new sample, then resume
bash "$HERE/../make_data.sh" 4 300 "$TMP/data" > /dev/null
nf_run "$TMP" trace3.tsv resume.nf -resume
new=$(nf_count "$TMP/trace3.tsv" COUNT_READS COMPLETED); old=$(nf_count "$TMP/trace3.tsv" COUNT_READS CACHED)
summ=$(nf_count "$TMP/trace3.tsv" SUMMARISE COMPLETED)
if [[ "$new" == 1 && "$old" == 3 && "$summ" == 1 ]]; then
    pass "A new sample runs 1 new task; the other 3 come from the cache" "SUMMARISE re-runs"
else
    fail "A new sample runs 1 new task; the other 3 come from the cache" "COUNT_READS new=$new cached=$old, SUMMARISE runs=$summ"
fi
rows=$(grep -cE '^sample[0-9]+'$'\t' "$S" 2>/dev/null)
if [[ "$rows" == 4 ]]; then
    pass "The summary now lists 4 samples"
else
    fail "The summary now lists 4 samples" "${rows:-0} sample rows"
fi

finish "$ID"
