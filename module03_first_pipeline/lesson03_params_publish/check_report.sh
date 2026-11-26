#!/usr/bin/env bash
# Lesson 3.3 challenge checker: runs your report.nf with its own reads, title and output folder.
# Usage: bash check_report.sh [path/to/report.nf]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../tools/checklib.sh"
source "$HERE/../../tools/nflib.sh"
ID="3.3-challenge"
SCRIPT="${1:-$HERE/report.nf}"
N=4

echo "Checking $SCRIPT"
if ! nf_have; then
    fail "Nextflow is installed" "install it first (Lesson 2.2)"
    finish "$ID"; exit 1
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$SCRIPT" "$TMP/report.nf" 2>/dev/null || { fail "report.nf exists" "copy main.nf to report.nf first"; finish "$ID"; exit 1; }
bash "$HERE/../make_data.sh" "$N" 300 "$TMP/fresh" > /dev/null

if (cd "$TMP" && nextflow lint report.nf > lint.log 2>&1); then
    pass "report.nf passes 'nextflow lint'"
else
    fail "report.nf passes 'nextflow lint'" "$(grep -m1 -iE 'error' "$TMP/lint.log")"
fi

# Run 1: everything given on the command line
if nf_run "$TMP" trace1.tsv report.nf --reads 'fresh/*.fastq' --title 'Batch 7' -output-dir published; then
    pass "Runs with --reads, --title and -output-dir"
else
    fail "Runs with --reads, --title and -output-dir" "$(nf_error "$TMP")"
fi

S="$TMP/published/summary.tsv"
if [[ -f "$S" && ! -L "$S" ]]; then
    pass "summary.tsv is published as a real copy"
elif [[ -L "$S" ]]; then
    fail "summary.tsv is published as a real copy" "it's a symlink into work/: use mode 'copy'"
else
    fail "summary.tsv is published as a real copy" "no published/summary.tsv"
fi

for f in "$TMP"/fresh/*.fastq; do
    awk -v s="$(basename "$f" .fastq)" 'END { print s "\t" NR / 4 }' "$f"
done | sort > "$TMP/expected.tsv"
if [[ -f "$S" && "$(head -n 1 "$S")" == "# Batch 7" ]] && diff -q <(tail -n +2 "$S") "$TMP/expected.tsv" > /dev/null; then
    pass "Summary = '# Batch 7' line + sorted counts" "$N samples"
else
    fail "Summary = '# Batch 7' line + sorted counts" "first lines: $(head -n 2 "$S" 2>/dev/null | tr '\t\n' ' ;')"
fi

n=$(find "$TMP/published/counts" -name '*.count.tsv' 2>/dev/null | wc -l | tr -d ' ')
if [[ "$n" == "$N" ]]; then
    pass "Per-sample counts published in counts/" "$N files"
else
    fail "Per-sample counts published in counts/" "found $n file(s), expected $N"
fi

# Run 2: no --title, so the default from the params block must be used
nf_run "$TMP" trace2.tsv report.nf --reads 'fresh/*.fastq' -output-dir published_default -resume
if [[ "$(head -n 1 "$TMP/published_default/summary.tsv" 2>/dev/null)" == "# Read counts" ]]; then
    pass "Without --title, the summary says '# Read counts'"
else
    fail "Without --title, the summary says '# Read counts'" \
        "got: $(head -n 1 "$TMP/published_default/summary.tsv" 2>/dev/null || nf_error "$TMP")"
fi

finish "$ID"
