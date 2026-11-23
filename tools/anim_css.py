#!/usr/bin/env python3
"""Generate CSS keyframes for the course's lesson animations.

Each animation lives in includes/anim/<name>.html as an inline SVG inside
<figure class="nf-anim nf-anim--<name>">. Timings here are percentages of the
animation's cycle. Run:  python3 tools/anim_css.py
Output: docs/stylesheets/anim-lessons.css  (listed in mkdocs.yml extra_css)

Helpers
  show(sel, a, b)            opacity 1 between a% and b%, else 0
  glow(sel, a, b, colour)    fill = colour between a% and b%
  move(sel, a, b, dx, dy, until)   fade in at a%, travel to (dx,dy) by b%, visible until `until`%
  bar(sel, a, b)             progress bar grows 0→1 between a% and b%, holds, resets at the end
  steps_y(sel, [(start%, y), ...])  jump to translateY(y) at each start%
"""
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "docs" / "stylesheets" / "anim-lessons.css"
_rules: list[str] = []
_n = 0


def _name(prefix: str) -> str:
    global _n
    _n += 1
    return f"{prefix}-{_n}"


def _p(x: float) -> str:
    return f"{max(0.0, min(100.0, x)):.2f}%"


def _rule(anim: str, sel: str, dur: float, keyframes: str, base: str = "") -> None:
    name = _name(anim)
    _rules.append(
        f".nf-anim--{anim} {sel} {{ {base}animation: {name} {dur}s linear infinite; }}\n"
        f"@keyframes {name} {{ {keyframes} }}\n"
    )


def show(anim, sel, a, b, dur):
    e = 0.05
    kf = []
    if a > 0:
        kf.append(f"0%, {_p(a - e)} {{ opacity: 0; }}")
    kf.append(f"{_p(a)}, {_p(b)} {{ opacity: 1; }}")
    if b < 100:
        kf.append(f"{_p(b + e)}, 100% {{ opacity: 0; }}")
    _rule(anim, sel, dur, " ".join(kf), "opacity: 0; ")


def glow(anim, sel, a, b, dur, colour="var(--nb-glow)", rest="color-mix(in srgb, var(--nb-green) 8%, var(--nb-card))", prop="fill", windows=None):
    """Highlight between a% and b% (or several (a, b) windows)."""
    e = 0.05
    windows = windows or [(a, b)]
    kf, cursor = [], 0.0
    for wa, wb in windows:
        kf.append(f"{_p(cursor)}, {_p(wa - e)} {{ {prop}: {rest}; }}")
        kf.append(f"{_p(wa)}, {_p(wb)} {{ {prop}: {colour}; }}")
        cursor = wb + e
    if cursor < 100:
        kf.append(f"{_p(cursor)}, 100% {{ {prop}: {rest}; }}")
    _rule(anim, sel, dur, " ".join(kf))


def move(anim, sel, a, b, dx, dy, dur, until=None):
    until = b + 2 if until is None else until
    kf = (
        f"0%, {_p(a - 0.6)} {{ transform: translate(0, 0); opacity: 0; }} "
        f"{_p(a)} {{ transform: translate(0, 0); opacity: 1; }} "
        f"{_p(b)} {{ transform: translate({dx}px, {dy}px); opacity: 1; }} "
        f"{_p(until)} {{ transform: translate({dx}px, {dy}px); opacity: 1; }} "
        f"{_p(until + 0.6)}, 100% {{ transform: translate({dx}px, {dy}px); opacity: 0; }}"
    )
    _rule(anim, sel, dur, kf, "opacity: 0; ")


def bar(anim, sel, a, b, dur, hold=96):
    kf = (
        f"0%, {_p(a)} {{ transform: scaleX(0); }} "
        f"{_p(b)}, {_p(hold)} {{ transform: scaleX(1); }} "
        f"100% {{ transform: scaleX(0); }}"
    )
    _rule(anim, sel, dur, kf)


def steps_y(anim, sel, points, dur, hide_after=None):
    e = 0.05
    kf = []
    for i, (start, y) in enumerate(points):
        end = points[i + 1][0] - e if i + 1 < len(points) else (hide_after - e if hide_after else 100)
        kf.append(f"{_p(start)}, {_p(end)} {{ transform: translateY({y}px); opacity: 1; }}")
    if hide_after:
        kf.append(f"{_p(hide_after)}, 100% {{ transform: translateY({points[-1][1]}px); opacity: 0; }}")
    _rule(anim, sel, dur, " ".join(kf))


# ---------------------------------------------------------------------------
# Lesson 1.2 — a DAG executing (12 s)
# ---------------------------------------------------------------------------
D = 12
move("dag", ".dag-d1", 2, 8, 90, -63, D, until=8.5)
move("dag", ".dag-d2", 2, 8, 90, 57, D, until=8.5)
move("dag", ".dag-d3", 35, 38, 60, 0, D, until=38.5)
move("dag", ".dag-d4", 45, 50, 230, 60, D, until=50.5)
move("dag", ".dag-d5", 60, 64, 50, -60, D, until=64.5)
glow("dag", ".dag-reads", 0, 8, D)
glow("dag", ".dag-fastqc .nfa-box", 8, 45, D)
glow("dag", ".dag-trim .nfa-box", 8, 35, D)
glow("dag", ".dag-align .nfa-box", 38, 60, D)
glow("dag", ".dag-multiqc .nfa-box", 64, 82, D)
bar("dag", ".dag-fastqc .nfa-bar", 8, 45, D)
bar("dag", ".dag-trim .nfa-bar", 8, 35, D)
bar("dag", ".dag-align .nfa-bar", 38, 60, D)
bar("dag", ".dag-multiqc .nfa-bar", 64, 82, D)
show("dag", ".dag-fastqc .dag-check", 45, 97, D)
show("dag", ".dag-trim .dag-check", 35, 97, D)
show("dag", ".dag-align .dag-check", 60, 97, D)
show("dag", ".dag-multiqc .dag-check", 82, 97, D)
show("dag", ".dag-l1", 0, 35, D)
show("dag", ".dag-l2", 35, 60, D)
show("dag", ".dag-l3", 60, 82, D)
show("dag", ".dag-l4", 82, 100, D)

# ---------------------------------------------------------------------------
# Lesson 1.2 — join walking two differently-sorted files (14 s, 7 steps)
# ---------------------------------------------------------------------------
J = 14
S = [0, 13, 26, 40, 53, 66, 80]
steps_y("join", ".join-ptr-left", [(S[0], 0), (S[1], 30), (S[2], 60), (S[3], 90), (S[4], 120), (S[5], 150)], J, hide_after=S[6])
steps_y("join", ".join-ptr-right", [(S[0], 0), (S[1], 30), (S[2], 60), (S[3], 60), (S[4], 90), (S[5], 120)], J, hide_after=S[6])
for i, s in enumerate([S[0], S[1], S[3], S[4], S[5]], start=1):
    show("join", f".join-m{i}", s + 3, 97, J)
show("join", ".join-cmp", S[2], S[3], J)
show("join", ".join-skip-left", S[2] + 4, 97, J)
show("join", ".join-skip-right", S[6], 97, J)
for i, s in enumerate(S, start=1):
    end = S[i] if i < len(S) else 100
    show("join", f".join-l{i}", s, end, J)

# ---------------------------------------------------------------------------
# Lesson 2.1 — a pipe with and without pipefail (12 s, two phases)
# ---------------------------------------------------------------------------
P = 12
for phase in (0, 50):
    for k in range(3):
        a = phase + 3 + 4 * k
        move("pipe", f".pipe-dot{k + 1}-{phase}", a, a + 7, 90, 0, P, until=a + 7.2)
    show("pipe", f".pipe-gzip-exit-{phase}", phase + 20, phase + 49, P)
    show("pipe", f".pipe-awk-exit-{phase}", phase + 24, phase + 49, P)
    show("pipe", f".pipe-head-{phase}", phase, phase + 50, P)
    show("pipe", f".pipe-result-{phase}", phase + 29, phase + 50, P)
    show("pipe", f".pipe-verdict-{phase}", phase + 33, phase + 50, P)
glow("pipe", ".pipe-gzip", 0, 0, P, colour="var(--nb-bad-bg)", windows=[(20, 48), (70, 98)])
glow("pipe", ".pipe-awk", 0, 0, P, colour="var(--nb-ok-bg)", windows=[(24, 48), (74, 98)])

# ---------------------------------------------------------------------------
# Lesson 2.1 — staging inputs as symlinks, publishDir and deleting work/ (14 s)
# ---------------------------------------------------------------------------
T = 14
show("stage", ".stage-task", 5, 72, T)
show("stage", ".stage-task-ghost", 72, 98, T)
show("stage", ".stage-link-in", 12, 72, T)
show("stage", ".stage-entry-in", 10, 72, T)
show("stage", ".stage-out", 32, 72, T)
show("stage", ".stage-results", 45, 98, T)
show("stage", ".stage-link-out", 50, 72, T)
show("stage", ".stage-link-broken", 72, 98, T)
show("stage", ".stage-broken-label", 76, 98, T)
show("stage", ".stage-l1", 0, 32, T)
show("stage", ".stage-l2", 32, 45, T)
show("stage", ".stage-l3", 45, 72, T)
show("stage", ".stage-l4", 72, 100, T)

# ---------------------------------------------------------------------------
# Lesson 2.3 — -profile decides how a process gets its software (12 s, thirds)
# ---------------------------------------------------------------------------
R = 12
for i, (a, b) in enumerate([(0, 33.3), (33.4, 66.6), (66.7, 100)], start=1):
    show("prof", f".prof-cmd{i}", a, b, R)
    show("prof", f".prof-out{i}", a + 10, b, R)
    show("prof", f".prof-l{i}", a + 10, b, R)
    move("prof", f".prof-dot{i}", a + 2, a + 10, 90, 0, R, until=a + 10.5)

# ---------------------------------------------------------------------------
# Lesson 1.2 — portability: same pipeline, three places to run (12 s, thirds)
# ---------------------------------------------------------------------------
Q = 12
for i, (a, dy) in enumerate([(0, -75), (33.4, 0), (66.7, 75)], start=1):
    move("port", f".port-d{i}", a + 3, a + 20, 290, dy, Q, until=a + 28)
    glow("port", f".port-v{i}", a + 20, a + 31, Q, colour="var(--nb-ok-bg)")
    show("port", f".port-p{i}", a, min(a + 33.3, 100), Q)

HEADER = "/* GENERATED by tools/anim_css.py: edit that file, not this one. */\n"
OUT.write_text(HEADER + "\n".join(_rules))
print(f"wrote {OUT} ({len(_rules)} rules)")
