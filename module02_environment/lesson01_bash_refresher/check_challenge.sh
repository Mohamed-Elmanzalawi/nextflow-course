#!/usr/bin/env bash
# Auto-checker for the Lesson 2.1 challenge (count_reads_safe.sh).
# Usage: bash check_challenge.sh [path/to/script]
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../../tools/checklib.sh"
SCRIPT="$(cd "$(dirname "${1:-$HERE/count_reads_safe.sh}")" 2>/dev/null && pwd)/$(basename "${1:-count_reads_safe.sh}")"
ID="2.1-challenge"

echo "Checking $(basename "$SCRIPT")…"
if [[ ! -f "$SCRIPT" ]]; then
    fail "Script exists" "create count_reads_safe.sh in this folder"
    finish "$ID"; exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP" && bash "$HERE/make_data.sh" > /dev/null

t() { perl -e 'alarm 30; exec @ARGV' bash "$SCRIPT" "$@" > out.txt 2> err.txt; echo $?; }

rc=$(t data/good.fastq.gz)
if [[ $rc -eq 0 && "$(tr -d ' \n' < out.txt)" == "1000" ]]; then
    pass "Good file: prints 1000 and exits 0"
else
    fail "Good file: prints 1000 and exits 0" "got exit $rc and output '$(head -c 40 out.txt)'"
fi

rc=$(t data/truncated.fastq.gz)
if [[ $rc -ne 0 ]]; then pass "Corrupt file: exits with an error" "exit $rc"
else fail "Corrupt file: exits with an error" "exit 0, so a pipeline would think it worked"; fi
if [[ ! -s out.txt ]]; then pass "Corrupt file: prints no misleading count"
else fail "Corrupt file: prints no misleading count" "printed '$(head -c 40 out.txt | tr '\n' ' ')' on stdout"; fi

rc=$(t data/does_not_exist.fastq.gz)
if [[ $rc -ne 0 && -s err.txt && ! -s out.txt ]]; then pass "Missing file: error on stderr, non-zero exit" "exit $rc"
else fail "Missing file: error on stderr, non-zero exit" "exit $rc; stderr $( [[ -s err.txt ]] && echo used || echo empty ); stdout $( [[ -s out.txt ]] && echo used || echo empty )"; fi

rc=$(t)
if [[ $rc -ne 0 ]]; then pass "No argument: exits with an error" "exit $rc"
else fail "No argument: exits with an error" "exit 0"; fi

finish "$ID" "$(basename "$SCRIPT")"
