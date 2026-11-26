#!/usr/bin/env bash
# Lesson 4.3 challenge checker: runs your fixed qc.nf on good data, then on data with a truncated file.
# It copies qc.nf plus nextflow.config, bin/ and scripts/ from the lesson folder, if they exist.
# Usage: bash check_qc.sh [lesson_folder]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../tools/checklib.sh"
source "$HERE/../../tools/nflib.sh"
ID="4.3-challenge"
SRC="${1:-$HERE}"

echo "Checking the pipeline in $SRC"
if ! nf_have; then
    fail "Nextflow is installed" "install it first (Lesson 2.2)"
    finish "$ID"; exit 1
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/good" "$TMP/bad"
for d in good bad; do
    cp "$SRC/qc.nf" "$TMP/$d/" 2>/dev/null || { fail "qc.nf exists" "not found in $SRC"; finish "$ID"; exit 1; }
    for extra in nextflow.config bin scripts; do
        [[ -e "$SRC/$extra" ]] && cp -Rp "$SRC/$extra" "$TMP/$d/"
    done
    bash "$HERE/../make_data.sh" 3 400 "$TMP/$d/data" gz > /dev/null
done

if (cd "$TMP/good" && nextflow lint qc.nf > lint.log 2>&1); then
    pass "qc.nf passes 'nextflow lint'"
else
    fail "qc.nf passes 'nextflow lint'" "$(grep -m1 -E '^Error' "$TMP/good/lint.log")"
fi

# 1. Good data: the run must finish and the report must be right
if nf_run "$TMP/good" trace.tsv qc.nf; then
    pass "The pipeline runs on good data" "bugs 1 and 2 fixed"
else
    fail "The pipeline runs on good data" "$(nf_error "$TMP/good")"
fi
expected=$(for f in "$TMP"/good/data/*.fastq.gz; do
    s=$(basename "$f" .fastq.gz)
    printf '%s\t%s\t50.0\n' "$s" "$(gzip -cd "$f" | awk 'END { print NR / 4 }')"
done | sort)
if [[ "$(cat "$TMP/good/results/qc_report.tsv" 2>/dev/null)" == "$expected" ]]; then
    pass "results/qc_report.tsv has the right reads and mean length" "3 samples"
else
    fail "results/qc_report.tsv has the right reads and mean length" \
        "got: $(head -n 2 "$TMP/good/results/qc_report.tsv" 2>/dev/null | tr '\t\n' ' ;')"
fi

# 2. A truncated .gz must make READ_STATS fail, not report a wrong count
head -c 9000 "$TMP/bad/data/sample3.fastq.gz" > "$TMP/bad/data/broken.fastq.gz"
nf_run "$TMP/bad" trace.tsv qc.nf
status=$?
# count READ_STATS failures with a non-zero exit code (a pipe error), not "missing output" (exit 0)
failed=$(awk -F'\t' 'NR == 1 { for (i = 1; i <= NF; i++) c[$i] = i; next }
    $c["name"] ~ /^READ_STATS/ && $c["status"] == "FAILED" && $c["exit"] != 0 && $c["exit"] != "-" { n++ }
    END { print n + 0 }' "$TMP/bad/trace.tsv" 2>/dev/null || echo 0)
if [[ "$status" != 0 && "$failed" -ge 1 ]]; then
    pass "A truncated file makes READ_STATS fail (bug 3 fixed)"
else
    fail "A truncated file makes READ_STATS fail (bug 3 fixed)" \
        "run exit=$status, failed READ_STATS tasks=$failed: the broken file was counted silently"
fi

finish "$ID"
