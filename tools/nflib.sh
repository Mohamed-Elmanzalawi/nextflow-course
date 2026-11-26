# Helpers for checkers that run a Nextflow pipeline. Source after checklib.sh.
#
#   nf_have                          -> true if `nextflow` is on PATH
#   nf_run <dir> <trace> [args...]   -> run `nextflow run` inside <dir>, log to <dir>/run.log,
#                                       write the task trace to <dir>/<trace>; returns Nextflow's exit code
#   nf_count <trace> <PROCESS> <STATUS>  -> number of tasks of that process with that status
#                                           (COMPLETED, CACHED, FAILED, ...)
#   nf_error <dir>                   -> first useful error line from <dir>/run.log
#
# Success is judged from the trace file and output files, never from console text:
# the console looks different in a normal terminal and in "agent mode" (NXF_AGENT_MODE).

nf_have() { command -v nextflow > /dev/null 2>&1; }

nf_run() {
    local dir="$1" trace="$2"; shift 2
    (cd "$dir" && perl -e 'alarm 600; exec @ARGV' \
        nextflow run "$@" -ansi-log false -with-trace "$trace" > run.log 2>&1)
}

nf_count() {
    [[ -f "$1" ]] || { echo 0; return; }
    awk -F'\t' -v p="$2" -v s="$3" '
        NR == 1 { for (i = 1; i <= NF; i++) col[$i] = i; next }
        { split($col["name"], a, " "); if (a[1] == p && $col["status"] == s) n++ }
        END { print n + 0 }' "$1"
}

nf_error() {
    grep -m1 -E 'ERROR|Error|error:|Caused by|Missing|not declared|required' "$1/run.log" 2>/dev/null \
        | cut -c1-160
}
