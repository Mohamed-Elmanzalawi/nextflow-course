# Shared helpers for the course's checker scripts. Source this file; don't run it.
#
#   pass "criterion name" ["detail"]
#   fail "criterion name" ["detail"]
#   finish <check-id> ["info"]   -> writes progress/checks/<check-id>.json
#
# The course website reads progress/checks/*.json, so results show up there
# automatically while `mkdocs serve` is running.

CHECK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_CRIT=()

pass() { _CRIT+=("1|$1|${2:-}"); printf '  \033[32m✓ PASS\033[0m  %s%s\n' "$1" "${2:+ — $2}"; }
fail() { _CRIT+=("0|$1|${2:-}"); printf '  \033[31m✗ FAIL\033[0m  %s%s\n' "$1" "${2:+ — $2}"; }

# Wall-clock time in seconds with decimals (macOS `date` has no %N).
now() { python3 -c 'import time; print(time.time())'; }
elapsed() { awk -v a="$1" -v b="$2" 'BEGIN{printf "%.1f", b - a}'; }

finish() {
    python3 - "${CHECK_OUT:-$CHECK_ROOT/progress/checks}" "$1" "${2:-}" "${_CRIT[@]}" <<'PY'
import datetime, json, os, sys
out, cid, info, *crit = sys.argv[1:]
os.makedirs(out, exist_ok=True)
criteria = []
for c in crit:
    ok, name, detail = c.split("|", 2)
    criteria.append({"name": name, "passed": ok == "1", "detail": detail})
data = {
    "id": cid,
    "passed": bool(criteria) and all(c["passed"] for c in criteria),
    "criteria": criteria,
    "info": info,
    "timestamp": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
}
with open(os.path.join(out, cid + ".json"), "w") as fh:
    json.dump(data, fh, indent=1)
n = sum(c["passed"] for c in criteria)
print(f"\n{'🎉 PASSED' if data['passed'] else 'Not passed yet'} ({n}/{len(criteria)} criteria).")
print("Result saved. The course website updates automatically (or click 'Refresh status').")
PY
}
