#!/usr/bin/env bash
# Auto-checker for Lesson 2.4: VS Code Nextflow extension + the course folder under Git.
# Usage: bash check_git.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../../tools/checklib.sh"
ID="2.4-git"
REPO="${GIT_ROOT:-$CHECK_ROOT}"

echo "Checking VS Code and Git for ${REPO}…"

if { command -v code > /dev/null 2>&1 && code --list-extensions 2>/dev/null | grep -qi '^nextflow\.nextflow$'; } \
   || compgen -G "$HOME/.vscode/extensions/nextflow.nextflow-*" > /dev/null; then
    pass "VS Code Nextflow extension installed"
else
    fail "VS Code Nextflow extension installed" "run: code --install-extension nextflow.nextflow"
fi

if git -C "$REPO" rev-parse --is-inside-work-tree > /dev/null 2>&1 \
   && [[ "$(git -C "$REPO" rev-parse --show-toplevel)" == "$(cd "$REPO" && pwd -P)" ]]; then
    pass "Course folder is a Git repository"
    n=$(git -C "$REPO" rev-list --count HEAD 2>/dev/null || echo 0)
    if (( n >= 2 )); then pass "At least 2 commits" "$n commits"
    else fail "At least 2 commits" "found $n"; fi

    missing=()
    for p in work/x .nextflow/x .nextflow.log .nextflow.log.1 site/x; do
        git -C "$REPO" check-ignore -q "$p" || missing+=("$p")
    done
    if (( ${#missing[@]} == 0 )); then pass ".gitignore covers Nextflow runtime files and site/"
    else fail ".gitignore covers Nextflow runtime files and site/" "not ignored: ${missing[*]}"; fi

    tracked=$(git -C "$REPO" ls-files | grep -E '(^|/)(work/|\.nextflow/|\.nextflow\.log)' | head -n 3)
    if [[ -z "$tracked" ]]; then pass "No Nextflow runtime files committed"
    else fail "No Nextflow runtime files committed" "remove from Git: $(tr '\n' ' ' <<< "$tracked")"; fi

    tags=$(git -C "$REPO" tag | head -n 3 | tr '\n' ' ')
    if [[ -n "$tags" ]]; then pass "Challenge: a tagged milestone exists" "$tags"
    else fail "Challenge: a tagged milestone exists" "no tags yet"; fi
else
    fail "Course folder is a Git repository" "run 'git init' in $REPO"
    fail "At least 2 commits" "needs a repository first"
    fail ".gitignore covers Nextflow runtime files and site/" "needs a repository first"
    fail "No Nextflow runtime files committed" "needs a repository first"
    fail "Challenge: a tagged milestone exists" "needs a repository first"
fi

finish "$ID" "$(git -C "$REPO" log -1 --format='last commit: %s' 2>/dev/null)"
