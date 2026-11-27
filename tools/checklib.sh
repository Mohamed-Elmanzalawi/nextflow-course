# Shared helpers for the course's checker scripts. Source this file; don't run it.
#
#   pass "criterion name" ["detail"]
#   fail "criterion name" ["detail"]
#   finish <check-id> ["info"]   -> writes progress/checks/<check-id>.json
#                                    and prints a result code
#
# The local course website reads progress/checks/*.json, so results show up
# there automatically while `mkdocs serve` is running. The online site can't
# see that folder; there the learner pastes the printed result code instead.

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
print("Result saved. The local course website updates automatically (or click 'Refresh status').")

# Result code for the online site, which can't read progress/checks/.
# Format NFC1:<id>:<passed>/<total>:<unix time>:<fnv1a-32 of the rest, hex>.
# The checksum only catches typos and cut-off pastes; it is not a signature.
body = f"NFC1:{cid}:{n}/{len(criteria)}:{int(datetime.datetime.now().timestamp())}"
h = 0x811C9DC5
for b in body.encode():
    h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF
print(f"Online site? Paste this result code into the checker box:\n  {body}:{h:08x}")
PY
}
