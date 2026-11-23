#!/usr/bin/env bash
# Auto-checker for the Lesson 1.2 challenge (annotate_fixed.sh).
# Usage: bash check_challenge.sh [path/to/script]
# Runs your script under three different locales in temporary folders.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../../tools/checklib.sh"
SCRIPT="$(cd "$(dirname "${1:-$HERE/annotate_fixed.sh}")" 2>/dev/null && pwd)/$(basename "${1:-annotate_fixed.sh}")"
ID="1.2-challenge"

echo "Checking $(basename "$SCRIPT")…"
if [[ ! -f "$SCRIPT" ]]; then
    fail "Script exists" "create annotate_fixed.sh in this folder"
    finish "$ID"; exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

LOCALES=(C en_US.UTF-8 ja_JP.UTF-8)
all_ok=1; complete=1
for loc in "${LOCALES[@]}"; do
    d="$TMP/$loc"; mkdir -p "$d"; cd "$d"
    cp "$SCRIPT" annotate.sh && cp "$HERE/make_data.sh" . && bash make_data.sh > /dev/null
    if ! LC_ALL="$loc" perl -e 'alarm 60; exec @ARGV' bash annotate.sh > run.log 2>&1; then
        all_ok=0
    fi
    n=$( [[ -f results/annotated.tsv ]] && wc -l < results/annotated.tsv | tr -d ' ' || echo 0)
    [[ "$n" == 6 ]] || complete=0
    echo "  ($loc: $n of 6 genes annotated)"
done

if (( all_ok )); then pass "Runs without errors in every locale"; else fail "Runs without errors in every locale"; fi
if (( complete )); then
    pass "All 6 genes annotated in every locale"
else
    fail "All 6 genes annotated in every locale" "some locale still loses genes"
fi
if [[ -f "$TMP/C/results/annotated.tsv" ]] \
   && cmp -s "$TMP/C/results/annotated.tsv" "$TMP/en_US.UTF-8/results/annotated.tsv" \
   && cmp -s "$TMP/C/results/annotated.tsv" "$TMP/ja_JP.UTF-8/results/annotated.tsv"; then
    pass "Output is byte-for-byte identical in every locale"
else
    fail "Output is byte-for-byte identical in every locale" "the same input should give the same file, whoever runs it"
fi

finish "$ID" "$(basename "$SCRIPT")"
