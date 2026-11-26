#!/usr/bin/env bash
# Lesson 3.1 challenge checker: runs your greet.nf on a fresh copy and checks the results.
# Usage: bash check_greet.sh [path/to/greet.nf]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../tools/checklib.sh"
source "$HERE/../../tools/nflib.sh"
ID="3.1-challenge"
SCRIPT="${1:-$HERE/greet.nf}"

echo "Checking $SCRIPT"
if ! nf_have; then
    fail "Nextflow is installed" "install it first (Lesson 2.2)"
    finish "$ID"; exit 1
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$SCRIPT" "$TMP/greet.nf" 2>/dev/null || { fail "greet.nf exists" "not found: $SCRIPT"; finish "$ID"; exit 1; }

if (cd "$TMP" && nextflow lint greet.nf > lint.log 2>&1); then
    pass "greet.nf passes 'nextflow lint'"
else
    fail "greet.nf passes 'nextflow lint'" "$(grep -m1 -iE 'error' "$TMP/lint.log")"
fi

if nf_run "$TMP" trace.tsv greet.nf; then
    pass "The pipeline runs without errors"
else
    fail "The pipeline runs without errors" "$(nf_error "$TMP")"
fi

n=$(nf_count "$TMP/trace.tsv" GREET COMPLETED)
if [[ "$n" == 3 ]]; then
    pass "Process GREET ran 3 tasks" "one per name"
else
    fail "Process GREET ran 3 tasks" "found $n GREET task(s)"
fi

ok=0; missing=""
for name in Ada Rosalind Barbara; do
    f=$(find "$TMP/work" -name "greeting_${name}.txt" 2>/dev/null | head -n 1)
    if [[ -n "$f" && "$(cat "$f")" == "Hello, ${name}!" ]]; then
        ok=$((ok + 1))
    else
        missing="${missing:+$missing, }greeting_${name}.txt"
    fi
done
if [[ "$ok" == 3 ]]; then
    pass "Each greeting file says 'Hello, <name>!'"
else
    fail "Each greeting file says 'Hello, <name>!'" "missing or wrong: $missing"
fi

finish "$ID" "Nextflow $(nextflow -version 2>/dev/null | sed -nE 's/.*version ([0-9][^ ]*).*/\1/p' | head -n 1)"
