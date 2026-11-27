#!/usr/bin/env bash
# Re-validate the checker scripts: every starter must FAIL and every reference
# solution must PASS. Run it before handing over a new module, and after any
# Nextflow upgrade or change to tools/checklib.sh, tools/nflib.sh or the data scripts.
#
# Usage: bash tools/validate_checkers.sh [--head] [--all] [id ...]
#   --head   test the last commit instead of the working tree (use this if you
#            edited lesson files while studying: the "starter" would be your answer)
#   --all    also run the machine checks (2.2 install, 2.3 containers, 2.4 git)
#            and Capstone 1 (needs Docker or conda; several minutes)
#   id ...   only these checks, e.g. 5.1 5.3 capstone1
#   MODES="false"   only one agent mode (default: "false true")
#
# Nothing is written to progress/checks/: every run gets its own CHECK_OUT.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HEAD_ONLY=0; ALL=0; ONLY=()
for a in "$@"; do
    case "$a" in
        --head) HEAD_ONLY=1 ;;
        --all) ALL=1 ;;
        -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
        *) ONLY+=("$a") ;;
    esac
done
MODES="${MODES:-false true}"
command -v nextflow > /dev/null || { echo "nextflow is not on PATH"; exit 2; }
# A broken Java setup would make every solution "fail"; stop early instead.
NXF_VERSION_LINE=$(nextflow -version 2>&1 | grep -m1 -oE 'version [0-9][^ ]*') \
    || { echo "nextflow is on PATH but doesn't run:"; nextflow -version 2>&1 | tail -n 5; exit 2; }
echo "Nextflow $NXF_VERSION_LINE"

# id | checker | starter (the learner's starting file) | solution
# The starter is the file the lesson tells the learner to start from; for
# "copy X to Y" challenges that is X. 4.3 tests a whole lesson folder.
CASES=(
  "1.1|module01_intro/lesson01_what_is_nextflow/check_challenge.sh|naive_pipeline.sh|1.1/naive_pipeline_v2.sh"
  "1.2|module01_intro/lesson02_reproducibility/check_challenge.sh|annotate.sh|1.2/annotate_fixed.sh"
  "2.1|module02_environment/lesson01_bash_refresher/check_challenge.sh|count_reads.sh|2.1/count_reads_safe.sh"
  "3.1|module03_first_pipeline/lesson01_anatomy/check_greet.sh|greet.nf|3.1/greet.nf"
  "3.2|module03_first_pipeline/lesson02_processes_workflows/check_gc.sh|main.nf|3.2/gc.nf"
  "3.3|module03_first_pipeline/lesson03_params_publish/check_report.sh|main.nf|3.3/report.nf"
  "3.4|module03_first_pipeline/lesson04_resume/check_resume.sh|main.nf|3.4/resume.nf"
  "4.1|module04_processes/lesson01_process_blocks/check_fix_me.sh|fix_me.nf|4.1/fix_me.nf"
  "4.2|module04_processes/lesson02_directives/check_retry.sh|retry.nf|4.2/retry.nf"
  "4.3|module04_processes/lesson03_task_isolation/check_qc.sh|.|4.3"
  "4.4|module04_processes/lesson04_inputs_outputs/check_chunks.sh|chunks.nf|4.4/chunks.nf"
  "5.1|module05_channels/lesson01_queue_value/check_fix_ref.sh|fix_ref.nf|5.1/fix_ref.nf"
  "5.2|module05_channels/lesson02_factories/check_read_sheet.sh|read_sheet.nf|5.2/read_sheet.nf"
  "5.3|module05_channels/lesson03_operators/check_puzzle.sh|puzzle.nf|5.3/puzzle.nf"
  "5.4|module05_channels/lesson04_meta_maps/check_to_meta.sh|to_meta.nf|5.4/to_meta.nf"
)
SLOW=("capstone1|capstone1/check_capstone.sh|main.nf|capstone1/main.nf")
# Checks of the machine itself (no starter or solution): they must PASS on a set-up machine.
MACHINE=(
  "2.2|module02_environment/lesson02_install/check_install.sh"
  "2.3|module02_environment/lesson03_containers/check_containers.sh"
  "2.4|module02_environment/lesson04_vscode_git/check_git.sh"
)
(( ALL )) && CASES+=("${SLOW[@]}")

wanted() {
    (( ${#ONLY[@]} == 0 )) && return 0
    local w; for w in "${ONLY[@]}"; do [[ "$1" == "$w" ]] && return 0; done; return 1
}

# A private copy of the course, so checkers can't touch the real lesson folders.
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
TREE="$WORK/course"; mkdir -p "$TREE"
if (( HEAD_ONLY )); then
    git -C "$REPO" archive HEAD | tar -x -C "$TREE"
    for d in module05_channels/data capstone1/data; do   # downloaded data: saves time
        [[ -d "$REPO/$d" ]] && mkdir -p "$TREE/$d" && cp -Rp "$REPO/$d/." "$TREE/$d/"
    done
    echo "Testing the last commit ($(git -C "$REPO" log -1 --format=%h))."
else
    rsync -a --exclude .git --exclude site --exclude work --exclude '.nextflow*' \
          --exclude results --exclude 'progress/checks/*.json' "$REPO/" "$TREE/"
    echo "Testing the working tree."
fi
SOL="$TREE/includes/solutions"

# run_check <label> <expect PASS|FAIL> <checker> [args...]  (env CFG_OVERRIDE optional)
FAILURES=(); N=0
run_check() {
    local label="$1" expect="$2" checker="$3"; shift 3
    local id out log got
    id=$(grep -m1 -oE '^ID="[^"]+"' "$checker" | cut -d'"' -f2)
    for mode in $MODES; do
        out="$WORK/out/$label-$expect-$mode"; mkdir -p "$out"; log="$out/log.txt"
        (cd "$(dirname "$checker")" && CHECK_OUT="$out" NXF_AGENT_MODE="$mode" bash "$checker" "$@") > "$log" 2>&1
        got=$(python3 -c 'import json,sys; print("PASS" if json.load(open(sys.argv[1]))["passed"] else "FAIL")' \
              "$out/$id.json" 2>/dev/null || echo "NO RESULT")
        N=$((N + 1))
        if [[ "$got" == "$expect" ]]; then
            printf '  \033[32mok\033[0m    %-10s %-8s expected %s, got %s (agent mode %s)\n' "$label" "" "$expect" "$got" "$mode"
        else
            printf '  \033[31mWRONG\033[0m %-10s %-8s expected %s, got %s (agent mode %s)\n' "$label" "" "$expect" "$got" "$mode"
            grep -E 'FAIL|PASS' "$log" | sed 's/^/          /'
            FAILURES+=("$label: expected $expect, got $got (agent mode $mode) — log: $log")
        fi
    done
}

for c in "${CASES[@]}"; do
    IFS='|' read -r label checker starter solution <<< "$c"
    wanted "$label" || continue
    checker="$TREE/$checker"; lesson="$(dirname "$checker")"
    echo "$label"
    if [[ "$label" == "4.3" ]]; then
        # The checker takes a folder: the lesson folder as given, then with the solution applied.
        run_check "$label" FAIL "$checker" "$lesson"
        fixed="$WORK/fixed-4.3"; cp -Rp "$lesson" "$fixed"; cp -Rp "$SOL/$solution/." "$fixed/"
        run_check "$label" PASS "$checker" "$fixed"
    else
        run_check "$label" FAIL "$checker" "$lesson/$starter"
        run_check "$label" PASS "$checker" "$SOL/$solution"
    fi
done

if (( ALL )); then
    for c in "${MACHINE[@]}"; do
        IFS='|' read -r label checker <<< "$c"
        wanted "$label" || continue
        echo "$label (this machine)"
        # 2.4 inspects the real repository, so it runs in place; the others run on the copy.
        if [[ "$label" == "2.4" ]]; then run_check "$label" PASS "$REPO/$checker"
        elif [[ "$label" == "2.3" ]]; then
            NF_CONFIG="$SOL/2.3/nextflow.config" run_check "$label" PASS "$TREE/$checker"
        else run_check "$label" PASS "$TREE/$checker"; fi
    done
fi

echo
if (( ${#FAILURES[@]} == 0 )); then
    echo "All $N checker runs behaved as expected."
else
    echo "${#FAILURES[@]} of $N checker runs did NOT behave as expected:"
    printf '  - %s\n' "${FAILURES[@]}"
    trap - EXIT; echo "(logs kept in $WORK)"
    exit 1
fi
