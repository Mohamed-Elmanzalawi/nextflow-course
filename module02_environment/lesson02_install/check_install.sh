#!/usr/bin/env bash
# Auto-checker for Lesson 2.2: is Java + Nextflow installed and working?
# Usage: bash check_install.sh      (needs internet for the 'hello' test pipeline)
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../../tools/checklib.sh"
ID="2.2-install"
info=()

echo "Checking your Java + Nextflow installation…"

# ---- Java ------------------------------------------------------------------
if jv_line=$(java -version 2>&1 | head -n 1) && [[ "$jv_line" == *version* ]]; then
    jv=$(sed -E 's/.*version "([^"]+)".*/\1/' <<< "$jv_line")
    major=${jv%%.*}; [[ "$major" == 1 ]] && major=$(cut -d. -f2 <<< "$jv")
    if (( major >= 17 && major <= 26 )); then
        pass "Java 17–26 available" "Java $jv"
    else
        fail "Java 17–26 available" "found Java $jv; Nextflow needs 17 to 26"
    fi
    info+=("Java $jv")
else
    fail "Java 17–26 available" "no working Java found (on macOS, /usr/bin/java is only a placeholder)"
fi

# ---- Nextflow --------------------------------------------------------------
if command -v nextflow > /dev/null 2>&1; then
    nfv=$(nextflow -version 2>/dev/null | sed -nE 's/.*version ([0-9][^ ]*).*/\1/p' | head -n 1)
    if [[ -n "$nfv" ]]; then
        pass "Nextflow on your PATH" "version $nfv at $(command -v nextflow)"
        info+=("Nextflow $nfv")
    else
        fail "Nextflow on your PATH" "found $(command -v nextflow) but it didn't report a version"
    fi
else
    fail "Nextflow on your PATH" "'nextflow' not found; did you add \$HOME/.local/bin to PATH and open a new terminal?"
fi

# ---- nextflow info ---------------------------------------------------------
if command -v nextflow > /dev/null 2>&1 && nextflow info > /dev/null 2>&1; then
    pass "'nextflow info' runs"
else
    fail "'nextflow info' runs"
fi

# ---- hello pipeline --------------------------------------------------------
if command -v nextflow > /dev/null 2>&1; then
    TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
    if (cd "$TMP" && perl -e 'alarm 300; exec @ARGV' nextflow run hello -ansi-log false > hello.log 2>&1) \
       && grep -q 'completed=4' "$TMP/hello.log"; then
        pass "'nextflow run hello' succeeds" "4 tasks completed"
    else
        fail "'nextflow run hello' succeeds" "$(tail -n 3 "$TMP/hello.log" 2>/dev/null | tr '\n' ' ')"
    fi
else
    fail "'nextflow run hello' succeeds" "needs Nextflow first"
fi

joined=""; for x in "${info[@]:-}"; do [[ -n "$x" ]] && joined="${joined:+$joined · }$x"; done
finish "$ID" "$joined"
