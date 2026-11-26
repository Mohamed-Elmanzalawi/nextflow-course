#!/usr/bin/env bash
# Lesson 4.1 challenge checker: your fixed fix_me.nf must run, give the right numbers, and have a stub.
# Usage: bash check_fix_me.sh [path/to/fix_me.nf]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../tools/checklib.sh"
source "$HERE/../../tools/nflib.sh"
ID="4.1-challenge"
SCRIPT="${1:-$HERE/fix_me.nf}"
N=3

echo "Checking $SCRIPT"
if ! nf_have; then
    fail "Nextflow is installed" "install it first (Lesson 2.2)"
    finish "$ID"; exit 1
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$SCRIPT" "$TMP/fix_me.nf" 2>/dev/null || { fail "fix_me.nf exists" "not found: $SCRIPT"; finish "$ID"; exit 1; }
bash "$HERE/../make_data.sh" "$N" 300 "$TMP/data" > /dev/null

if (cd "$TMP" && nextflow lint fix_me.nf > lint.log 2>&1); then
    pass "fix_me.nf passes 'nextflow lint'"
else
    fail "fix_me.nf passes 'nextflow lint'" "$(grep -m1 -E '^Error' "$TMP/lint.log")"
fi

# Real run: check every report against an independent calculation
if nf_run "$TMP" trace.tsv fix_me.nf; then
    pass "The real run completes"
else
    fail "The real run completes" "$(nf_error "$TMP")"
fi
ok=0; bad=""
for f in "$TMP"/data/*.fastq; do
    s=$(basename "$f" .fastq)
    want=$(printf 'sample: %s\nreads: %s\ngc_bases: %s' "$s" \
        "$(awk 'END { print NR / 4 }' "$f")" \
        "$(awk 'NR % 4 == 2' "$f" | tr -cd 'GC' | wc -c | tr -d ' ')")
    got=$(cat "$(find "$TMP/work" -name "${s}.report.txt" -type f -size +0 2>/dev/null | head -n 1)" 2>/dev/null)
    if [[ "$got" == "$want" ]]; then ok=$((ok + 1)); else bad="${bad:+$bad, }$s"; fi
done
if [[ "$ok" == "$N" ]]; then
    pass "Every report has the right sample, reads and gc_bases" "$N samples"
else
    fail "Every report has the right sample, reads and gc_bases" "wrong or missing: ${bad:-all}"
fi

# Stub run in a separate work dir: outputs must exist and be empty (made by touch, not by the real script)
if (cd "$TMP" && perl -e 'alarm 300; exec @ARGV' nextflow run fix_me.nf -stub -w work_stub \
        -ansi-log false -with-trace trace_stub.tsv > stub.log 2>&1); then
    n=$(find "$TMP/work_stub" -name '*.report.txt' -type f -empty | wc -l | tr -d ' ')
    if [[ "$n" == "$N" ]] && ! grep -rqs 'sleep 3' "$TMP"/work_stub/*/*/.command.sh; then
        pass "'-stub' runs the stub block" "$N empty report files"
    else
        fail "'-stub' runs the stub block" "found $n empty report(s); is there a stub: section?"
    fi
else
    fail "'-stub' runs the stub block" "$(grep -m1 -E 'ERROR|Error' "$TMP/stub.log")"
fi

finish "$ID"
