#!/usr/bin/env bash
# Lesson 4.4 challenge checker: runs your chunks.nf on 4 fresh samples of different sizes.
# Usage: bash check_chunks.sh [path/to/chunks.nf]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../tools/checklib.sh"
source "$HERE/../../tools/nflib.sh"
ID="4.4-challenge"
SCRIPT="${1:-$HERE/chunks.nf}"
PER=300            # reads per chunk used by the checker
# make_data.sh 4 200 -> 200, 450, 700, 950 reads -> 1 + 2 + 3 + 4 = 10 chunks; only sample1 is small

echo "Checking $SCRIPT"
if ! nf_have; then
    fail "Nextflow is installed" "install it first (Lesson 2.2)"
    finish "$ID"; exit 1
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$SCRIPT" "$TMP/chunks.nf" 2>/dev/null || { fail "chunks.nf exists" "not found: $SCRIPT"; finish "$ID"; exit 1; }
bash "$HERE/../make_data.sh" 4 200 "$TMP/fresh" > /dev/null

if (cd "$TMP" && nextflow lint chunks.nf > lint.log 2>&1); then
    pass "chunks.nf passes 'nextflow lint'"
else
    fail "chunks.nf passes 'nextflow lint'" "$(grep -m1 -E '^Error' "$TMP/lint.log")"
fi

if nf_run "$TMP" trace.tsv chunks.nf --reads 'fresh/*.fastq' --reads_per_chunk "$PER"; then
    pass "Runs with --reads_per_chunk $PER"
else
    fail "Runs with --reads_per_chunk $PER" "$(nf_error "$TMP")"
fi

n=$(nf_count "$TMP/trace.tsv" COUNT_CHUNK COMPLETED)
if [[ "$n" == 10 ]]; then
    pass "COUNT_CHUNK runs once per chunk" "10 tasks for 1 + 2 + 3 + 4 chunks"
else
    fail "COUNT_CHUNK runs once per chunk" "found $n task(s), expected 10"
fi

out=$(find "$TMP/work" -name chunk_counts.tsv -type f 2>/dev/null | head -n 1)
totals=$(awk -F'\t' '{ s = $1; sub(/^chunk_/, "", s); sub(/_[0-9]+$/, "", s); t[s] += $2 }
    END { for (k in t) print k, t[k] }' "${out:-/dev/null}" 2>/dev/null | sort | tr '\n' ';')
if [[ "$totals" == "sample1 200;sample2 450;sample3 700;sample4 950;" ]]; then
    pass "chunk_counts.tsv adds up to every sample's read count"
else
    fail "chunk_counts.tsv adds up to every sample's read count" "per-sample totals: ${totals:-no chunk_counts.tsv}"
fi

small=$(find "$TMP/work" -name '*.small' -type f 2>/dev/null | xargs -n1 basename 2>/dev/null | sort -u | tr '\n' ' ')
# the file must also be a declared output: optional, emitted as 'small'
declared=$(grep -E "^[[:space:]]*path .*\.small" "$TMP/chunks.nf" | grep -E "optional:[[:space:]]*true" | grep -cE "emit:[[:space:]]*small")
if [[ "$small" == "sample1.small " && "$declared" -ge 1 ]]; then
    pass "Only the small sample emits a .small file (optional output)"
else
    fail "Only the small sample emits a .small file (optional output)" "files: ${small:-none}; declared as optional output 'small': $([[ "$declared" -ge 1 ]] && echo yes || echo no)"
fi

finish "$ID"
