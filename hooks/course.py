"""MkDocs hook: interactive questions + course index for the Learning Nextflow site.

Authoring syntax (inside any lesson page, any indentation):

    ```quiz
    id: 1.1-q4                # unique across the course
    type: single              # single | multi | number | open | steps | check
    concept: dataflow         # tag used for the "concepts to review" list
    question: "Markdown text"
    options:                  # single / multi
      - text: "Option A"
      - text: "Option B"
        correct: true
    answer: 20                # number
    tolerance: 3              # number (absolute)
    unit: s                   # number (display only)
    model: "Markdown model answer"   # open
    steps: ["step 1", "step 2"]      # steps
    check: 1.1-challenge             # check: id written by a checker script
    command: "bash check_challenge.sh"   # check: shown to the learner
    solution: includes/solutions/1.1/naive_pipeline_v2.sh  # check: revealed after a run
    explain: "Markdown shown after answering"
    hint: "Optional Markdown hint"
    required: true            # default true; counts toward lesson completion
    ```

Lesson pages declare front matter:  lesson: "1.1", module: 1, level: 1
"""

from __future__ import annotations

import glob
import html
import json
import os
import re

import markdown
import yaml

FENCE = re.compile(
    r"^(?P<indent>[ \t]*)```quiz[ \t]*\n(?P<body>.*?)\n(?P=indent)```[ \t]*$",
    re.M | re.S,
)
TOKEN = "NBQTOKEN{n}X"
TYPES = {"single", "multi", "number", "open", "steps", "check"}
LABELS = {
    "single": "Quick check",
    "multi": "Pick all that apply",
    "number": "Your number",
    "open": "In your own words",
    "steps": "Do it",
    "check": "Auto-checked",
}

_page_specs: dict[str, list[dict]] = {}
_lessons: dict[str, dict] = {}
_seen_ids: dict[str, str] = {}
_root = "."


def _md(text: str | None) -> str:
    if not text:
        return ""
    return markdown.markdown(
        str(text),
        extensions=["tables", "pymdownx.superfences", "pymdownx.inlinehilite", "pymdownx.highlight"],
    )


def on_config(config, **kwargs):
    global _root
    _root = os.path.dirname(os.path.abspath(config.config_file_path))
    return config


def on_pre_build(config, **kwargs):
    _page_specs.clear()
    _lessons.clear()
    _seen_ids.clear()


def on_page_markdown(markdown_src, page, config, files, **kwargs):
    specs: list[dict] = []

    def repl(match: re.Match) -> str:
        indent = match.group("indent")
        body = "\n".join(
            line[len(indent):] if line.startswith(indent) else line
            for line in match.group("body").split("\n")
        )
        try:
            spec = yaml.safe_load(body) or {}
        except yaml.YAMLError as exc:
            raise ValueError(f"{page.file.src_path}: bad quiz YAML: {exc}") from exc
        qid, qtype = spec.get("id"), spec.get("type")
        if not qid or qtype not in TYPES:
            raise ValueError(f"{page.file.src_path}: quiz needs an id and a type in {sorted(TYPES)}: {spec}")
        if qid in _seen_ids and _seen_ids[qid] != page.file.src_path:
            raise ValueError(f"duplicate quiz id {qid} in {page.file.src_path} and {_seen_ids[qid]}")
        _seen_ids[qid] = page.file.src_path
        if qtype == "check" and spec.get("solution"):
            sol_path = os.path.join(_root, spec["solution"])
            if not os.path.isfile(sol_path):
                raise ValueError(f"{page.file.src_path}: solution file not found: {spec['solution']}")
            with open(sol_path, encoding="utf-8") as fh:
                spec["solution_text"] = fh.read()
            spec["solution_name"] = os.path.basename(spec["solution"])
        specs.append(spec)
        return f"\n\n{indent}{TOKEN.format(n=len(specs) - 1)}\n\n"

    new_src = FENCE.sub(repl, markdown_src)
    _page_specs[page.file.src_path] = specs

    meta = page.meta or {}
    if "lesson" in meta:
        _lessons[page.file.src_path] = {
            "lesson": str(meta["lesson"]),
            "module": int(meta.get("module", 0)),
            "level": int(meta.get("level", 0)),
            "title": page.title or meta.get("title", ""),
            "url": page.url,
            "items": [
                {
                    "id": s["id"],
                    "type": s["type"],
                    "concept": s.get("concept", ""),
                    "required": bool(s.get("required", True)),
                    "check": s.get("check"),
                    "n": len(s.get("steps", []) or []),
                }
                for s in specs
            ],
        }
    return new_src


def _widget(spec: dict) -> str:
    qtype = spec["type"]
    client = {
        "id": spec["id"],
        "type": qtype,
        "concept": spec.get("concept", ""),
        "label": spec.get("label", LABELS[qtype]),
        "question": _md(spec.get("question")),
        "explain": _md(spec.get("explain")),
        "hint": _md(spec.get("hint")),
        "required": bool(spec.get("required", True)),
    }
    if qtype in ("single", "multi"):
        client["options"] = [
            {"html": _md(o.get("text")), "correct": bool(o.get("correct", False))}
            for o in spec.get("options", [])
        ]
        if not any(o["correct"] for o in client["options"]):
            raise ValueError(f"quiz {spec['id']}: no correct option")
    elif qtype == "number":
        client.update(
            answer=float(spec["answer"]),
            tolerance=float(spec.get("tolerance", 0)),
            unit=spec.get("unit", ""),
        )
    elif qtype == "open":
        client["model"] = _md(spec.get("model"))
    elif qtype == "steps":
        client["steps"] = [_md(s) for s in spec.get("steps", [])]
    elif qtype == "check":
        client.update(
            check=spec.get("check", spec["id"]),
            command=spec.get("command", ""),
            solution=spec.get("solution_text"),
            solution_name=spec.get("solution_name"),
        )
    payload = json.dumps(client).replace("</", "<\\/")
    return (
        f'<div class="nbq nbq--{qtype}" id="q-{html.escape(spec["id"])}" '
        f'data-qid="{html.escape(spec["id"])}">'
        f'<script type="application/json" class="nbq__spec">{payload}</script>'
        f'<noscript><p>Enable JavaScript to answer this question.</p></noscript>'
        f"</div>"
    )


def on_page_content(content, page, config, files, **kwargs):
    specs = _page_specs.get(page.file.src_path, [])
    for n, spec in enumerate(specs):
        token = TOKEN.format(n=n)
        new = content.replace(f"<p>{token}</p>", _widget(spec))
        if new == content:
            raise ValueError(f"{page.file.src_path}: could not place quiz {spec['id']}")
        content = new
    return content


def _lesson_key(lesson: str):
    return tuple(int(p) for p in lesson.split(".") if p.isdigit())


def on_post_build(config, **kwargs):
    out_dir = os.path.join(config.site_dir, "assets")
    os.makedirs(out_dir, exist_ok=True)

    lessons = sorted(_lessons.values(), key=lambda l: _lesson_key(l["lesson"]))
    with open(os.path.join(out_dir, "course-index.json"), "w", encoding="utf-8") as fh:
        json.dump({"lessons": lessons}, fh, indent=1)

    checks = {}
    for path in sorted(glob.glob(os.path.join(_root, "progress", "checks", "*.json"))):
        try:
            with open(path, encoding="utf-8") as fh:
                data = json.load(fh)
            checks[data["id"]] = data
        except (OSError, ValueError, KeyError):
            continue
    with open(os.path.join(out_dir, "checks.json"), "w", encoding="utf-8") as fh:
        json.dump(checks, fh, indent=1)
