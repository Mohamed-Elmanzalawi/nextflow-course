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


def bar_win(anim, sel, a, b, off, dur):
    """Bar grows 0→1 between a% and b%, stays full until off%, then vanishes at once."""
    e = 0.05
    kf = (
        f"0%, {_p(a)} {{ transform: scaleX(0); }} "
        f"{_p(b)}, {_p(off)} {{ transform: scaleX(1); }} "
        f"{_p(off + e)}, 100% {{ transform: scaleX(0); }}"
    )
    _rule(anim, sel, dur, kf)


def track(anim, sel, points, dur):
    """Full control: points = [(pct, dx, dy, opacity), ...] in time order.
    Every keyframe sets both transform and opacity, so nothing is left undefined."""
    kf = []
    if points[0][0] > 0:
        p0 = points[0]
        kf.append(f"0% {{ transform: translate({p0[1]}px, {p0[2]}px); opacity: {p0[3]}; }}")
    for pct, dx, dy, op in points:
        kf.append(f"{_p(pct)} {{ transform: translate({dx}px, {dy}px); opacity: {op}; }}")
    if points[-1][0] < 100:
        pl = points[-1]
        kf.append(f"100% {{ transform: translate({pl[1]}px, {pl[2]}px); opacity: {pl[3]}; }}")
    _rule(anim, sel, dur, " ".join(kf), "opacity: 0; ")


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

# ---------------------------------------------------------------------------
# Lesson 3.1 — anatomy of a run: script → task → work folder → ✔ (12 s, quarters)
# ---------------------------------------------------------------------------
A = 12
HL = "var(--nb-wait-bg)"
CLEAR = "rgba(0, 0, 0, 0)"
glow("anat", ".anat-hl-call", 0, 0, A, colour=HL, rest=CLEAR, windows=[(2, 25)])
glow("anat", ".anat-hl-script", 0, 0, A, colour=HL, rest=CLEAR, windows=[(50, 75)])
glow("anat", ".anat-hl-output", 0, 0, A, colour=HL, rest=CLEAR, windows=[(75, 97)])
show("anat", ".anat-task", 27, 97, A)
show("anat", ".anat-folder", 33, 97, A)
show("anat", ".anat-f-sh", 52, 97, A)
show("anat", ".anat-f-run", 55, 97, A)
show("anat", ".anat-f-out", 64, 97, A)
show("anat", ".anat-f-exit", 77, 97, A)
show("anat", ".anat-console", 80, 97, A)
glow("anat", ".anat-folder-box", 0, 0, A, colour="var(--nb-ok-bg)", windows=[(80, 97)])
for i, (a, b) in enumerate([(0, 25), (25, 50), (50, 75), (75, 100)], start=1):
    show("anat", f".anat-l{i}", a, b, A)

# ---------------------------------------------------------------------------
# Lesson 3.2 — each workflow line wires up part of the dataflow (15 s, 3 steps + finale)
# ---------------------------------------------------------------------------
W = 15
glow("wire", ".wire-hl1", 0, 0, W, colour=HL, rest=CLEAR, windows=[(1, 28)])
glow("wire", ".wire-hl2", 0, 0, W, colour=HL, rest=CLEAR, windows=[(28, 60)])
glow("wire", ".wire-hl3", 0, 0, W, colour=HL, rest=CLEAR, windows=[(60, 90)])
for k in range(3):
    # read tokens: appear in the channel, travel into their task box, vanish
    track("wire", f".wire-r{k + 1}", [(4 + 3 * k, 0, 0, 0), (6 + 3 * k, 0, 0, 1), (31, 0, 0, 1),
                                       (38, 92, 0, 1), (39, 92, 0, 0)], W)
    # count tokens: appear at the box exit, wait in counts_ch, travel into the bundle
    track("wire", f".wire-c{k + 1}", [(50, 0, 0, 0), (52, 0, 0, 1), (62, 0, 0, 1),
                                       (69, 78, 35 * (1 - k), 1), (70, 78, 35 * (1 - k), 0)], W)
    bar("wire", f".wire-bar{k + 1}", 38, 50, W, hold=97)
glow("wire", ".wire-task", 0, 0, W, colour="var(--nb-wait-bg)", windows=[(38, 50)])
track("wire", ".wire-bundle", [(69, 0, 0, 0), (70, 0, 0, 1), (75, 0, 0, 1), (81, 85, 17, 1), (82, 85, 17, 0)], W)
glow("wire", ".wire-sum", 0, 0, W, colour="var(--nb-wait-bg)", windows=[(82, 90)])
show("wire", ".wire-out", 89, 99, W)
show("wire", ".wire-l1", 0, 28, W)
show("wire", ".wire-l2", 28, 60, W)
show("wire", ".wire-l3", 60, 90, W)
show("wire", ".wire-l4", 90, 100, W)

# ---------------------------------------------------------------------------
# Lesson 3.3 — where params.title comes from: four layers, the highest wins (12 s, quarters)
# ---------------------------------------------------------------------------
P3 = 12
for i, (a, b) in enumerate([(0, 25), (25, 50), (50, 75), (75, 100)], start=1):
    show("parm", f".parm-layer{i}", a + 2, 99, P3)
    show("parm", f".parm-v{i}", a + 6, b, P3)
    show("parm", f".parm-l{i}", a, b, P3)
    glow("parm", f".parm-box{i}", 0, 0, P3, colour="var(--nb-ok-bg)", windows=[(a + 6, b)])
    track("parm", f".parm-arrow{i}", [(a + 3, 0, 14, 0), (a + 6, 0, 0, 1), (b - 1, 0, 0, 1), (b, 0, 0, 0)], P3)

# ---------------------------------------------------------------------------
# Lesson 3.4 — -resume: what runs again and what comes from the cache (16 s, quarters)
# ---------------------------------------------------------------------------
R4 = 16
Q4 = [(0, 25), (25, 50), (50, 75), (75, 100)]
# which cards run (instead of coming from the cache) in each phase: c1..c3 = COUNT_READS, c4 = SUMMARISE
RUNS = {1: [1, 2, 3, 4], 2: [], 3: [4], 4: [1, 4]}
for c in range(1, 5):
    run_windows = [(a + 4, a + 16) for p, (a, b) in enumerate(Q4, start=1) if c in RUNS[p]]
    if run_windows:
        glow("res", f".res-card{c}", 0, 0, R4, colour="var(--nb-wait-bg)", windows=run_windows)
    for p, (a, b) in enumerate(Q4, start=1):
        if c in RUNS[p]:
            bar_win("res", f".res-bar{c}-{p}", a + 4, a + 16, b - 0.3, R4)
            show("res", f".res-ran{c}-{p}", a + 16, b - 0.3, R4)
        else:
            show("res", f".res-cached{c}-{p}", a + 4, b - 0.3, R4)
# hashes: c4 changes at phase 3, c1 at phase 4 (and c4 again, its input changed)
show("res", ".res-h1a", 0, 75, R4); show("res", ".res-h1b", 75.05, 100, R4)
show("res", ".res-h4a", 0, 50, R4); show("res", ".res-h4b", 50.05, 75, R4); show("res", ".res-h4c", 75.05, 100, R4)
for p, (a, b) in enumerate(Q4, start=1):
    show("res", f".res-cmd{p}", a, b, R4)
    show("res", f".res-l{p}", a, b, R4)

# ---------------------------------------------------------------------------
# Lesson 4.1 — two languages in one script block: Nextflow first, then Bash (12 s, thirds)
# ---------------------------------------------------------------------------
I = 12
glow("intp", ".intp-nf", 0, 0, I, colour="var(--nb-wait-bg)", rest=CLEAR, windows=[(3, 33)])
glow("intp", ".intp-esc", 0, 0, I, colour="var(--nb-bad-bg)", rest=CLEAR, windows=[(36, 66)])
glow("intp", ".intp-filled", 0, 0, I, colour="var(--nb-ok-bg)", rest=CLEAR, windows=[(36, 66)])
glow("intp", ".intp-bashvar", 0, 0, I, colour="var(--nb-ok-bg)", rest=CLEAR, windows=[(70, 97)])
show("intp", ".intp-sh", 34, 99, I)
show("intp", ".intp-out", 70, 99, I)
show("intp", ".intp-l1", 0, 33.3, I)
show("intp", ".intp-l2", 33.4, 66.6, I)
show("intp", ".intp-l3", 66.7, 100, I)

# ---------------------------------------------------------------------------
# Lesson 4.2 — retry with more memory on every attempt (12 s, thirds + finale)
# ---------------------------------------------------------------------------
T2 = 12
for i, a in enumerate([2, 30, 58], start=1):
    show("rtry", f".rtry-card{i}", a, 99, T2)
    bar_win("rtry", f".rtry-mem{i}", a + 2, a + 10, 99, T2)
    show("rtry", f".rtry-res{i}", a + 14, 99, T2)
    show("rtry", f".rtry-l{i}", a - 2 if i > 1 else 0, a + 26, T2)
glow("rtry", ".rtry-box1", 0, 0, T2, colour="var(--nb-bad-bg)", windows=[(16, 99)])
glow("rtry", ".rtry-box2", 0, 0, T2, colour="var(--nb-bad-bg)", windows=[(44, 99)])
glow("rtry", ".rtry-box3", 0, 0, T2, colour="var(--nb-ok-bg)", windows=[(72, 99)])
show("rtry", ".rtry-l4", 84, 100, T2)

# ---------------------------------------------------------------------------
# Lesson 4.3 — the debugging loop (15 s, five steps)
# ---------------------------------------------------------------------------
D5 = 15
for i in range(5):
    a, b = 20 * i, 20 * (i + 1)
    glow("dbug", f".dbug-step{i + 1}", 0, 0, D5, colour="var(--nb-wait-bg)", windows=[(a + 1, b - 1)])
    show("dbug", f".dbug-term{i + 1}", a + 1, b - 1, D5)
    show("dbug", f".dbug-l{i + 1}", a, b, D5)

# ---------------------------------------------------------------------------
# Lesson 4.4 — named outputs, flatten() and an optional output (14 s, quarters)
# ---------------------------------------------------------------------------
E4 = 14
show("emit", ".emit-in1", 1, 48, E4)
show("emit", ".emit-in2", 51, 99, E4)
glow("emit", ".emit-split", 0, 0, E4, colour="var(--nb-wait-bg)", windows=[(3, 12), (53, 62)])
track("emit", ".emit-list3", [(12, 0, 0, 0), (13, 0, 0, 1), (26, 0, 0, 1), (30, 70, 0, 1), (31, 70, 0, 0)], E4)
for k in range(3):
    track("emit", f".emit-c{k + 1}", [(30, 0, 0, 0), (31, 0, 0, 1), (37, 0, 0, 1), (45, 110, 0, 1), (46, 110, 0, 0)], E4)
glow("emit", ".emit-count", 0, 0, E4, colour="var(--nb-wait-bg)", windows=[(45, 50), (88, 94)])
track("emit", ".emit-list1", [(62, 0, 0, 0), (63, 0, 0, 1), (76, 0, 0, 1), (80, 70, 0, 1), (81, 70, 0, 0)], E4)
track("emit", ".emit-c4", [(80, 0, 0, 0), (81, 0, 0, 1), (84, 0, 0, 1), (88, 110, 0, 1), (89, 110, 0, 0)], E4)
track("emit", ".emit-small", [(63, 0, 0, 0), (64, 0, 0, 1), (98, 0, 0, 1), (99, 0, 0, 0)], E4)
show("emit", ".emit-none", 13, 48, E4)
for i, (a, b) in enumerate([(0, 25), (25, 50), (50, 75), (75, 100)], start=1):
    show("emit", f".emit-l{i}", a, b, E4)

HEADER = "/* GENERATED by tools/anim_css.py: edit that file, not this one. */\n"
OUT.write_text(HEADER + "\n".join(_rules))
print(f"wrote {OUT} ({len(_rules)} rules)")
