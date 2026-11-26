#!/usr/bin/env bash
# Lesson 5.3 challenge checker: runs your puzzle.nf quietly and compares each part (A-F) with the goal.
# Usage: bash check_puzzle.sh [path/to/puzzle.nf]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../tools/checklib.sh"
source "$HERE/../../tools/nflib.sh"
ID="5.3-challenge"
SCRIPT="${1:-$HERE/puzzle.nf}"

echo "Checking $SCRIPT"
if ! nf_have; then fail "Nextflow is installed" "install it first (Lesson 2.2)"; finish "$ID"; exit 1; fi
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$SCRIPT" "$TMP/puzzle.nf" 2>/dev/null || { fail "puzzle.nf exists" "not found: $SCRIPT"; finish "$ID"; exit 1; }

# Normal (non-agent) console mode + -q: only the view() lines are printed
if (cd "$TMP" && NXF_AGENT_MODE=false perl -e 'alarm 300; exec @ARGV' nextflow -q run puzzle.nf > out.txt 2> err.txt); then
    pass "puzzle.nf runs"
else
    fail "puzzle.nf runs" "$(grep -m1 -E 'Error|ERROR' "$TMP/err.txt" "$TMP/out.txt" | cut -c1-150)"
fi

check_part() {   # letter, description, expected lines (sorted, joined by |)
    local got
    got=$(grep -E "^$1: " "$TMP/out.txt" | sort | paste -sd '|' -)
    if [[ "$got" == "$3" ]]; then
        pass "$1. $2"
    else
        fail "$1. $2" "got: ${got:-nothing}"
    fi
}
check_part A "Squares of the even numbers" "A: 100|A: 16|A: 36|A: 4|A: 64"
check_part B "Read count and GC% joined per sample" "B: [cov_a, 100, 37.9]|B: [cov_b, 100, 38.4]|B: [hsa_rna, 4159, 48.1]"
check_part C "Lanes grouped per patient" "C: [pt01, [L001, L002, L003]]|C: [pt02, [L001, L002]]"
check_part D "Only sensible sample-reference pairs" "D: [cov_a, MN908947]|D: [cov_b, MN908947]|D: [hsa_rna, GRCh38]"
check_part E "Total reads, as one number" "E: 4359"
check_part F "Number of FASTQ files, as one number" "F: 5"
finish "$ID"
