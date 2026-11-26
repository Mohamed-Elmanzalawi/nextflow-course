#!/usr/bin/env bash
# Lesson 4.2 challenge checker: runs your retry.nf twice and reads tag, attempt and memory from the trace.
# Usage: bash check_retry.sh [path/to/retry.nf]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../tools/checklib.sh"
source "$HERE/../../tools/nflib.sh"
ID="4.2-challenge"
SCRIPT="${1:-$HERE/retry.nf}"

echo "Checking $SCRIPT"
if ! nf_have; then
    fail "Nextflow is installed" "install it first (Lesson 2.2)"
    finish "$ID"; exit 1
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$SCRIPT" "$TMP/retry.nf" 2>/dev/null || { fail "retry.nf exists" "not found: $SCRIPT"; finish "$ID"; exit 1; }
printf "trace {\n    fields = 'name,tag,attempt,memory,status,exit'\n}\n" > "$TMP/trace.config"

if (cd "$TMP" && nextflow lint retry.nf > lint.log 2>&1); then
    pass "retry.nf passes 'nextflow lint'"
else
    fail "retry.nf passes 'nextflow lint'" "$(grep -m1 -E '^Error' "$TMP/lint.log")"
fi

# Run 1: three samples that each need 3 GB
if nf_run "$TMP" trace1.tsv retry.nf -c trace.config --samples 'kiwi,mango,papaya'; then
    pass "All samples finish (after retries)"
else
    fail "All samples finish (after retries)" "$(nf_error "$TMP")"
fi

# attempt N must have N GB; the successful attempt must be the 3rd one
ladder=$(awk -F'\t' 'NR > 1 && $5 != "" {
        mem = $4; sub(/ GB/, "", mem)
        if (mem + 0 != $3 + 0) bad++
        if ($5 == "COMPLETED") { done++; if ($3 != 3) early++ }
    } END { print done + 0, bad + 0, early + 0 }' "$TMP/trace1.tsv" 2>/dev/null)
read -r done bad early <<< "${ladder:-0 0 0}"
if [[ "$done" == 3 && "$bad" == 0 && "$early" == 0 ]]; then
    pass "Memory grows 1 GB → 2 GB → 3 GB; each sample succeeds on attempt 3"
else
    fail "Memory grows 1 GB → 2 GB → 3 GB; each sample succeeds on attempt 3" \
        "completed=$done, attempts with the wrong memory=$bad"
fi

tags=$(awk -F'\t' 'NR > 1 && $5 == "COMPLETED" { print $2 }' "$TMP/trace1.tsv" 2>/dev/null | sort | tr '\n' ' ')
if [[ "$tags" == "kiwi mango papaya " ]]; then
    pass "Each task is tagged with its sample name"
else
    fail "Each task is tagged with its sample name" "tags: ${tags:-none}"
fi

# Run 2: a corrupt sample must stop the run at once, without retries
nf_run "$TMP" trace2.tsv retry.nf -c trace.config --samples 'kiwi,corrupt'
status=$?
tries=$(awk -F'\t' 'NR > 1 && $2 == "corrupt"' "$TMP/trace2.tsv" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$status" != 0 && "$tries" == 1 ]]; then
    pass "A non-memory error (exit 1) stops the run without retrying"
else
    fail "A non-memory error (exit 1) stops the run without retrying" "run exit=$status, 'corrupt' was tried $tries time(s)"
fi

finish "$ID"
