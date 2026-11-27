#!/usr/bin/env python3
"""Check that every external link in the course still answers.

Usage: python3 tools/check_links.py [-v]

Scans docs/, includes/ and mkdocs.yml for http(s) URLs, requests each one once
and lists those that fail. Exit status 1 if any link is broken.

Only the page itself is checked, not the #anchor: docs.seqera.io builds its
pages in the browser, so anchors need a real browser (Playwright) to verify.
Some sites refuse scripts (HTTP 403/429); those are listed separately as
"could not verify", to check by hand.
"""
import re
import sys
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
URL = re.compile(r"https?://[^\s<>\"'`)\]|]+")
SKIP = ("127.0.0.1", "localhost", "example.com", "example.org")
HEADERS = {"User-Agent": "Mozilla/5.0 (course link checker)", "Accept": "*/*"}


def find_urls():
    files = [ROOT / "mkdocs.yml", ROOT / "README.md"]
    for d in ("docs", "includes"):
        files += [p for p in (ROOT / d).rglob("*") if p.suffix in {".md", ".html", ".yml"}]
    urls = {}
    for f in files:
        for n, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
            for u in URL.findall(line):
                u = u.rstrip(".,;:!?*_")
                if any(s in u for s in SKIP) or "{" in u:
                    continue
                urls.setdefault(u.split("#")[0], []).append(f"{f.relative_to(ROOT)}:{n}")
    return urls


def status(url):
    for method in ("HEAD", "GET"):
        req = urllib.request.Request(url, method=method, headers=HEADERS)
        try:
            with urllib.request.urlopen(req, timeout=20) as r:
                return r.status
        except urllib.error.HTTPError as e:
            if method == "HEAD" and e.code in (403, 404, 405, 429, 501):
                continue  # some servers reject HEAD; retry with GET
            return e.code
        except Exception as e:  # DNS, timeout, TLS…
            if method == "GET":
                return f"{type(e).__name__}: {e}"
    return "no answer"


def main():
    verbose = "-v" in sys.argv
    urls = find_urls()
    with ThreadPoolExecutor(max_workers=8) as pool:
        results = dict(zip(urls, pool.map(status, urls)))
    broken = {u: s for u, s in results.items() if not (isinstance(s, int) and s < 400) and s not in (403, 429)}
    unsure = {u: s for u, s in results.items() if s in (403, 429)}
    if verbose:
        for u, s in sorted(results.items()):
            print(f"{s}  {u}")
    print(f"{len(urls)} external links checked: {len(results) - len(broken) - len(unsure)} ok, "
          f"{len(broken)} broken, {len(unsure)} could not verify.")
    for title, group in (("Broken", broken), ("Could not verify (site refuses scripts; open by hand)", unsure)):
        if group:
            print(f"\n{title}:")
            for u, s in sorted(group.items()):
                print(f"  {s}  {u}\n       used in {', '.join(urls[u][:3])}{' …' if len(urls[u]) > 3 else ''}")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
