#!/usr/bin/env bash
# Lesson 3.2 challenge checker: runs your gc.nf on 4 fresh samples and checks every result.
# Usage: bash check_gc.sh [path/to/gc.nf]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../tools/checklib.sh"
source "$HERE/../../tools/nflib.sh"
ID="3.2-challenge"
SCRIPT="${1:-$HERE/gc.nf}"
N=4

echo "Checking $SCRIPT on $N fresh samples"
if ! nf_have; then
    fail "Nextflow is installed" "install it first (Lesson 2.2)"
    finish "$ID"; exit 1
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$SCRIPT" "$TMP/gc.nf" 2>/dev/null || { fail "gc.nf exists" "copy main.nf to gc.nf first"; finish "$ID"; exit 1; }
bash "$HERE/../make_data.sh" "$N" 400 "$TMP/data" > /dev/null

if (cd "$TMP" && nextflow lint gc.nf > lint.log 2>&1); then
    pass "gc.nf passes 'nextflow lint'"
else
    fail "gc.nf passes 'nextflow lint'" "$(grep -m1 -iE 'error' "$TMP/lint.log")"
fi

if nf_run "$TMP" trace.tsv gc.nf; then
    pass "The pipeline runs without errors"
else
    fail "The pipeline runs without errors" "$(nf_error "$TMP")"
fi

c=$(nf_count "$TMP/trace.tsv" COUNT_READS COMPLETED); s=$(nf_count "$TMP/trace.tsv" SUMMARISE COMPLETED)
if [[ "$c" == "$N" && "$s" == 1 ]]; then
    pass "Read counting still works" "COUNT_READS ×$N, SUMMARISE ×1"
else
    fail "Read counting still works" "COUNT_READS ×$c, SUMMARISE ×$s (expected ×$N and ×1)"
fi

g=$(nf_count "$TMP/trace.tsv" GC_CONTENT COMPLETED)
if [[ "$g" == "$N" ]]; then
    pass "GC_CONTENT ran once per sample" "$N tasks"
else
    fail "GC_CONTENT ran once per sample" "found $g task(s), expected $N"
fi

# Expected GC% per sample, computed independently of your pipeline.
for f in "$TMP"/data/*.fastq; do
    awk -v s="$(basename "$f" .fastq)" 'NR % 4 == 2 { b += length($0); gc += gsub(/[GC]/, "") }
        END { printf "%s\t%.2f\n", s, 100 * gc / b }' "$f"
done | sort > "$TMP/expected.tsv"

out=$(find "$TMP/work" -name gc_summary.tsv -type f 2>/dev/null | head -n 1)
if [[ -z "$out" ]]; then
    fail "gc_summary.tsv has the right GC% for every sample" "no gc_summary.tsv was produced"
elif awk -F'\t' 'NR == FNR { e[$1] = $2; next }
        ($1 in e) && ($2 - e[$1] < 0.011) && (e[$1] - $2 < 0.011) { ok++ }
        END { exit !(ok == length(e) && FNR == length(e)) }' "$TMP/expected.tsv" "$out"; then
    pass "gc_summary.tsv has the right GC% for every sample" "$N lines"
else
    fail "gc_summary.tsv has the right GC% for every sample" "got: $(head -n 2 "$out" | tr '\t\n' ' ;')"
fi

finish "$ID"
