#!/usr/bin/env bash
# Auto-checker for the Lesson 1.1 challenge (naive_pipeline_v2.sh).
# Usage: bash check_challenge.sh [path/to/script]
# Runs your script on fresh data in a temporary folder; your own data/ and results/ are not touched.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../../tools/checklib.sh"
SCRIPT="$(cd "$(dirname "${1:-$HERE/naive_pipeline_v2.sh}")" 2>/dev/null && pwd)/$(basename "${1:-naive_pipeline_v2.sh}")"
ID="1.1-challenge"

echo "Checking $(basename "$SCRIPT") (takes up to ~1 minute)…"
if [[ ! -f "$SCRIPT" ]]; then
    fail "Script exists" "create naive_pipeline_v2.sh in this folder"
    finish "$ID"; exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

expected="$(for i in $(seq 1 10); do printf 'sample%s\t1000\n' "$i"; done | sort)"
summary_ok() { [[ -f results/summary.tsv ]] && [[ "$(sort results/summary.tsv)" == "$expected" ]]; }

# Run the learner's script with a 120 s safety limit.
run() { perl -e 'alarm 120; exec @ARGV' bash pipeline.sh > "$1" 2>&1; }

# ---- 1 + 2: parallel and correct ---------------------------------------------
mkdir "$TMP/a" && cd "$TMP/a"
cp "$SCRIPT" pipeline.sh && cp "$HERE/make_data.sh" . && bash make_data.sh 10 > /dev/null
t0=$(now); run run1.log; rc=$?; t1=$(now); d1=$(elapsed "$t0" "$t1")
if [[ $rc -ne 0 ]]; then
    fail "Runs without errors" "exit code $rc; last lines: $(tail -n 2 run1.log | tr '\n' ' ')"
else
    pass "Runs without errors"
fi
if awk -v d="$d1" 'BEGIN{exit !(d <= 10)}'; then
    pass "Samples run in parallel" "10 samples in ${d1}s (one at a time would take ~20s)"
else
    fail "Samples run in parallel" "10 samples took ${d1}s; one at a time takes ~20s"
fi
if summary_ok; then
    pass "Summary is correct" "10 samples × 1000 reads"
else
    fail "Summary is correct" "results/summary.tsv should list sample1–sample10 with 1000 reads each"
fi

# ---- 3: rerun skips finished work ---------------------------------------------
t0=$(now); run run2.log; t1=$(now); d2=$(elapsed "$t0" "$t1")
if awk -v d="$d2" 'BEGIN{exit !(d < 1.5)}' && summary_ok; then
    pass "Rerun skips finished samples" "rerun took ${d2}s"
else
    fail "Rerun skips finished samples" "rerun took ${d2}s (should be near-instant), or the summary changed"
fi

# ---- 4: survives an interruption ----------------------------------------------
mkdir "$TMP/b" && cd "$TMP/b"
cp "$SCRIPT" pipeline.sh && cp "$HERE/make_data.sh" . && bash make_data.sh 10 > /dev/null
set -m                                   # own process group, so we can kill the whole run
bash pipeline.sh > run_killed.log 2>&1 &
pid=$!
set +m
sleep 1
kill -TERM -- "-$pid" 2>/dev/null; wait "$pid" 2>/dev/null
run run3.log
if summary_ok; then
    pass "Recovers after being killed mid-run" "rerun produced a correct summary"
else
    fail "Recovers after being killed mid-run" "after an interrupted run, a rerun should still give a correct summary"
fi

finish "$ID" "$(basename "$SCRIPT")"
