/* Learning Nextflow — interactive questions, automatic progress, dashboard.
 * All learner state lives in localStorage under one key (per browser + site address).
 * Checker results (from terminal scripts) arrive via assets/checks.json.
 */
(function () {
  "use strict";

  var KEY = "nfcourse:v1";
  var CHEERS = ["Nice work!", "Spot on!", "Exactly right!", "You've got it!", "Great thinking!"];

  /* ---------- storage ---------------------------------------------------- */
  function load() {
    try {
      var raw = window.localStorage.getItem(KEY);
      var s = raw ? JSON.parse(raw) : null;
      if (s && s.v === 1 && s.items) return s;
    } catch (e) { /* storage unavailable or corrupt */ }
    return { v: 1, items: {}, visited: {} };
  }
  function save(state) {
    try { window.localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) { /* ignore */ }
  }
  function item(state, id) {
    if (!state.items[id]) state.items[id] = {};
    return state.items[id];
  }

  /* ---------- helpers ---------------------------------------------------- */
  function root() {
    try { if (window.__md_scope) return window.__md_scope; } catch (e) { /* ignore */ }
    return new URL("/", window.location.href);
  }
  function asset(path) { return new URL(path, root()).href; }
  function el(tag, cls, htmlText) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (htmlText !== undefined) n.innerHTML = htmlText;
    return n;
  }
  function text(tag, cls, t) {
    var n = el(tag, cls);
    n.textContent = t;
    return n;
  }
  function btn(label, cls) {
    var b = text("button", "nbq__btn " + (cls || ""), label);
    b.type = "button";
    return b;
  }
  function esc(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }
  function fetchJSON(path) {
    return fetch(asset(path), { cache: "no-store" })
      .then(function (r) { return r.ok ? r.json() : null; })
      .catch(function () { return null; });
  }
  var checksPromise = null;
  function getChecks(refresh) {
    if (!checksPromise || refresh) checksPromise = fetchJSON("assets/checks.json").then(function (c) { return c || {}; });
    return checksPromise;
  }
  function when(ts) {
    try { return new Date(ts).toLocaleString(); } catch (e) { return ts; }
  }

  /* ---------- feedback box ------------------------------------------------- */
  function feedback(box, ok, spec, extra) {
    box.innerHTML = "";
    box.className = "nbq__feedback " + (ok ? "is-ok" : "is-bad");
    var img = el("img", "nbq__flo");
    img.src = asset(ok ? "assets/flo/flo-idea.svg" : "assets/flo/flo-oops.svg");
    img.alt = ok ? "Flo celebrating" : "Flo looking surprised";
    var body = el("div", "nbq__feedback-body");
    body.appendChild(text("strong", "", ok ? CHEERS[Math.floor(Math.random() * CHEERS.length)] : "Not quite. Here's why:"));
    if (extra) body.appendChild(el("div", "", extra));
    if (spec.explain) body.appendChild(el("div", "nbq__explain", spec.explain));
    box.appendChild(img);
    box.appendChild(body);
    box.hidden = false;
  }

  function firstAttemptNote(st) {
    if (st.first === undefined) return "";
    return st.first ? "" : '<p class="nbq__note">Your first attempt is what counts for your score; retrying is still great practice.</p>';
  }

  /* ---------- renderers ---------------------------------------------------- */
  function renderChoice(root, spec, state) {
    var st = item(state, spec.id);
    var multi = spec.type === "multi";
    var list = el("div", "nbq__options");
    var inputs = [];
    spec.options.forEach(function (opt, i) {
      var lab = el("label", "nbq__option");
      var inp = document.createElement("input");
      inp.type = multi ? "checkbox" : "radio";
      inp.name = "nbq-" + spec.id;
      inp.value = String(i);
      lab.appendChild(inp);
      lab.appendChild(el("span", "nbq__option-text", opt.html));
      list.appendChild(lab);
      inputs.push(inp);
    });
    root.appendChild(list);
    var check = btn("Check answer", "nbq__btn--primary");
    var box = el("div", "nbq__feedback");
    box.hidden = true;
    root.appendChild(check);
    root.appendChild(box);

    function evaluate(sel) {
      var ok = spec.options.every(function (o, i) { return o.correct === (sel.indexOf(i) >= 0); });
      inputs.forEach(function (inp, i) {
        var lab = inp.parentNode;
        lab.classList.remove("is-right", "is-wrong");
        if (spec.options[i].correct && (multi || sel.indexOf(i) >= 0 || ok)) lab.classList.add("is-right");
        if (!spec.options[i].correct && sel.indexOf(i) >= 0) lab.classList.add("is-wrong");
      });
      return ok;
    }
    function show(sel, ok) {
      inputs.forEach(function (inp, i) { inp.checked = sel.indexOf(i) >= 0; });
      evaluate(sel);
      feedback(box, ok, spec, firstAttemptNote(st));
      root.parentNode.classList.add("is-answered");
    }
    check.addEventListener("click", function () {
      var sel = [];
      inputs.forEach(function (inp, i) { if (inp.checked) sel.push(i); });
      if (!sel.length) { box.hidden = false; box.className = "nbq__feedback"; box.textContent = "Pick an answer first."; return; }
      var ok = spec.options.every(function (o, i) { return o.correct === (sel.indexOf(i) >= 0); });
      if (st.first === undefined) st.first = ok;
      st.correct = ok; st.answer = sel; st.ts = new Date().toISOString();
      save(state); show(sel, ok); refreshLessonBars();
    });
    if (st.answer) show(st.answer, !!st.correct);
  }

  function renderNumber(root, spec, state) {
    var st = item(state, spec.id);
    var row = el("div", "nbq__row");
    var inp = document.createElement("input");
    inp.type = "number"; inp.step = "any"; inp.className = "nbq__input"; inp.setAttribute("aria-label", "Your answer");
    row.appendChild(inp);
    if (spec.unit) row.appendChild(text("span", "nbq__unit", spec.unit));
    var check = btn("Check answer", "nbq__btn--primary");
    row.appendChild(check);
    root.appendChild(row);
    var box = el("div", "nbq__feedback"); box.hidden = true; root.appendChild(box);
    function verdict(v) { return Math.abs(v - spec.answer) <= spec.tolerance + 1e-9; }
    function show(v) {
      var ok = verdict(v);
      var extra = "<p>Expected about <strong>" + esc(spec.answer) + (spec.unit ? " " + esc(spec.unit) : "") + "</strong>" +
        (spec.tolerance ? " (±" + esc(spec.tolerance) + ")" : "") + ". You said " + esc(v) + ".</p>" + firstAttemptNote(st);
      feedback(box, ok, spec, extra);
      root.parentNode.classList.add("is-answered");
    }
    check.addEventListener("click", function () {
      var v = parseFloat(inp.value);
      if (isNaN(v)) { box.hidden = false; box.className = "nbq__feedback"; box.textContent = "Type a number first."; return; }
      var ok = verdict(v);
      if (st.first === undefined) st.first = ok;
      st.correct = ok; st.answer = v; st.ts = new Date().toISOString();
      save(state); show(v); refreshLessonBars();
    });
    if (st.answer !== undefined) { inp.value = st.answer; show(st.answer); }
  }

  function renderOpen(root, spec, state) {
    var st = item(state, spec.id);
    var ta = document.createElement("textarea");
    ta.className = "nbq__textarea"; ta.rows = 4; ta.placeholder = "Type your answer here. It's saved automatically.";
    ta.setAttribute("aria-label", "Your answer");
    ta.value = st.text || "";
    ta.addEventListener("input", function () { st.text = ta.value; save(state); });
    root.appendChild(ta);
    var compare = btn("Compare with model answer", "nbq__btn--primary");
    root.appendChild(compare);
    var reveal = el("div", "nbq__model"); reveal.hidden = true;
    reveal.appendChild(text("p", "nbq__model-title", "Model answer"));
    reveal.appendChild(el("div", "", spec.model));
    if (spec.explain) reveal.appendChild(el("div", "nbq__explain", spec.explain));
    var rate = el("div", "nbq__rate");
    rate.appendChild(text("span", "nbq__rate-label", "How did your answer compare?"));
    [["got", "Got it"], ["partly", "Partly"], ["missed", "Missed it"]].forEach(function (r) {
      var b = btn(r[1], "nbq__btn--rate nbq__btn--" + r[0]);
      b.dataset.rating = r[0];
      b.addEventListener("click", function () {
        st.rating = r[0]; st.ts = new Date().toISOString(); save(state); paint(); refreshLessonBars();
      });
      rate.appendChild(b);
    });
    reveal.appendChild(rate);
    root.appendChild(reveal);
    function paint() {
      Array.prototype.forEach.call(rate.querySelectorAll("button"), function (b) {
        b.classList.toggle("is-selected", b.dataset.rating === st.rating);
      });
      if (st.rating) root.parentNode.classList.add("is-answered");
    }
    compare.addEventListener("click", function () {
      if (!ta.value.trim()) { ta.focus(); ta.placeholder = "Write something first: even a rough answer helps you learn!"; return; }
      st.revealed = true; save(state); reveal.hidden = false;
    });
    if (st.revealed) reveal.hidden = false;
    paint();
  }

  function renderSteps(root, spec, state) {
    var st = item(state, spec.id);
    if (!st.done) st.done = [];
    var list = el("ul", "nbq__steps");
    spec.steps.forEach(function (s, i) {
      var li = el("li");
      var lab = el("label", "nbq__step");
      var cb = document.createElement("input");
      cb.type = "checkbox"; cb.checked = !!st.done[i];
      cb.addEventListener("change", function () {
        st.done[i] = cb.checked; st.ts = new Date().toISOString(); save(state); paint(); refreshLessonBars();
      });
      lab.appendChild(cb);
      lab.appendChild(el("span", "", s));
      li.appendChild(lab);
      list.appendChild(li);
    });
    root.appendChild(list);
    function paint() {
      var all = spec.steps.every(function (_, i) { return st.done[i]; });
      root.parentNode.classList.toggle("is-answered", all);
    }
    paint();
  }

  function renderCheck(root, spec) {
    var cmd = el("div", "nbq__cmd");
    cmd.appendChild(text("span", "nbq__cmd-label", "Run in the lesson folder:"));
    cmd.appendChild(text("code", "", spec.command));
    root.appendChild(cmd);
    var status = el("div", "nbq__status");
    status.textContent = "Loading check status…";
    root.appendChild(status);
    var refresh = btn("Refresh status");
    root.appendChild(refresh);
    var sol = null;
    if (spec.solution) {
      var solBtn = btn("Show reference solution", "nbq__btn--solution");
      solBtn.disabled = true;
      solBtn.title = "Unlocks after you've run the checker at least once";
      sol = el("div", "nbq__solution"); sol.hidden = true;
      var pre = el("pre"); var code = el("code");
      code.textContent = spec.solution; pre.appendChild(code);
      sol.appendChild(text("p", "nbq__model-title", "Reference solution: " + (spec.solution_name || "")));
      sol.appendChild(pre);
      if (spec.explain) sol.appendChild(el("div", "nbq__explain", spec.explain));
      solBtn.addEventListener("click", function () { sol.hidden = !sol.hidden; solBtn.textContent = sol.hidden ? "Show reference solution" : "Hide reference solution"; });
      root.appendChild(solBtn);
      root.appendChild(sol);
    }
    function paint(checks) {
      var r = checks[spec.check];
      status.innerHTML = "";
      if (!r) {
        status.className = "nbq__status is-pending";
        status.textContent = "Not run yet. Run the command above in your terminal and this updates automatically.";
        return;
      }
      status.className = "nbq__status " + (r.passed ? "is-pass" : "is-fail");
      var n = (r.criteria || []).filter(function (c) { return c.passed; }).length;
      status.appendChild(text("strong", "", (r.passed ? "PASSED " : "Not passed yet ") + "(" + n + "/" + (r.criteria || []).length + " criteria) · last run " + when(r.timestamp)));
      var ul = el("ul", "nbq__criteria");
      (r.criteria || []).forEach(function (c) {
        var li = el("li", c.passed ? "is-pass" : "is-fail");
        li.textContent = (c.passed ? "✓ " : "✗ ") + c.name + (c.detail ? ": " + c.detail : "");
        ul.appendChild(li);
      });
      status.appendChild(ul);
      if (r.passed) root.parentNode.classList.add("is-answered");
      var sb = root.querySelector(".nbq__btn--solution");
      if (sb) { sb.disabled = false; sb.title = ""; }
    }
    getChecks().then(paint);
    refresh.addEventListener("click", function () { getChecks(true).then(function (c) { paint(c); refreshLessonBars(); }); });
  }

  function renderWidget(node, state) {
    if (node.dataset.ready) return;
    var raw = node.getAttribute("data-spec");
    if (!raw) return;
    var spec = JSON.parse(raw);
    node.dataset.ready = "1";
    var head = el("div", "nbq__head");
    head.appendChild(text("span", "nbq__badge", spec.label));
    if (!spec.required) head.appendChild(text("span", "nbq__optional", "optional"));
    node.appendChild(head);
    if (spec.question) node.appendChild(el("div", "nbq__question", spec.question));
    if (spec.hint) {
      var d = el("details", "nbq__hint");
      d.appendChild(text("summary", "", "Need a hint?"));
      d.appendChild(el("div", "", spec.hint));
      node.appendChild(d);
    }
    var body = el("div", "nbq__body");
    node.appendChild(body);
    if (spec.type === "single" || spec.type === "multi") renderChoice(body, spec, state);
    else if (spec.type === "number") renderNumber(body, spec, state);
    else if (spec.type === "open") renderOpen(body, spec, state);
    else if (spec.type === "steps") renderSteps(body, spec, state);
    else if (spec.type === "check") renderCheck(body, spec);
  }

  /* ---------- progress maths ---------------------------------------------- */
  function itemStatus(it, state, checks) {
    var st = state.items[it.id] || {};
    switch (it.type) {
      case "single": case "multi": case "number":
        return { attempted: st.first !== undefined, good: st.first === true, scored: true };
      case "open":
        return { attempted: !!st.rating, good: st.rating === "got", scored: true, partial: st.rating === "partly" };
      case "steps":
        var n = (st.done || []).filter(Boolean).length;
        return { attempted: it.n > 0 && n >= it.n, good: true, scored: false };
      case "check":
        var r = checks[it.check || it.id];
        return { attempted: !!r, good: !!(r && r.passed), scored: false, mustPass: true };
    }
    return { attempted: false, good: false, scored: false };
  }

  function lessonStats(lesson, state, checks) {
    var req = lesson.items.filter(function (i) { return i.required; });
    var done = 0, scored = 0, good = 0, complete = true, review = [];
    req.forEach(function (it) {
      var s = itemStatus(it, state, checks);
      var finished = s.attempted && (!s.mustPass || s.good);
      if (finished) done++; else complete = false;
      if (s.scored && s.attempted) { scored++; if (s.good) good++; }
      if (s.attempted && !s.good && (s.scored || s.mustPass)) review.push({ item: it, lesson: lesson });
    });
    lesson.items.filter(function (i) { return !i.required; }).forEach(function (it) {
      var s = itemStatus(it, state, checks);
      if (s.attempted && !s.good && s.scored) review.push({ item: it, lesson: lesson });
    });
    var started = done > 0 || !!(state.visited || {})[lesson.lesson];
    return {
      total: req.length, done: done, complete: complete && req.length > 0,
      started: started, score: scored ? Math.round((100 * good) / scored) : null, review: review,
    };
  }

  /* ---------- lesson mini progress ---------------------------------------- */
  var indexPromise = null;
  function getIndex() {
    if (!indexPromise) indexPromise = fetchJSON("assets/course-index.json").then(function (i) { return i || { lessons: [] }; });
    return indexPromise;
  }

  function refreshLessonBars() {
    var bars = document.querySelectorAll(".nb-lesson-progress");
    if (!bars.length) return;
    Promise.all([getIndex(), getChecks()]).then(function (res) {
      var index = res[0], checks = res[1], state = load();
      Array.prototype.forEach.call(bars, function (bar) {
        var lesson = index.lessons.filter(function (l) { return l.lesson === bar.dataset.lesson; })[0];
        if (!lesson) { bar.textContent = ""; return; }
        var s = lessonStats(lesson, state, checks);
        var pct = s.total ? Math.round((100 * s.done) / s.total) : 0;
        var pos = index.lessons.indexOf(lesson);
        var next = index.lessons[pos + 1];
        bar.innerHTML =
          '<div class="nb-bar"><span style="width:' + pct + '%"></span></div>' +
          "<p><strong>" + s.done + " of " + s.total + "</strong> activities done" +
          (s.score !== null ? " · first-try score <strong>" + s.score + "%</strong>" : "") +
          (s.complete ? ' · <span class="nb-done">Lesson complete! 🎉</span>' : "") + "</p>" +
          (s.complete && next ? '<p><a class="md-button md-button--primary" href="' + asset(next.url) + '">Next: ' + esc(next.title) + " →</a></p>" : "") +
          (s.complete && !next ? "<p>That's the last lesson written so far. Ask Claude for the next module whenever you're ready.</p>" : "") +
          '<p><a href="' + asset("progress/") + '">See your full progress →</a></p>';
      });
    });
  }

  /* ---------- dashboard --------------------------------------------------- */
  function renderDashboard(host) {
    host.textContent = "Loading your progress…";
    Promise.all([getIndex(), getChecks(true)]).then(function (res) {
      var index = res[0], checks = res[1], state = load();
      host.innerHTML = "";
      var lessons = index.lessons;
      var stats = lessons.map(function (l) { return lessonStats(l, state, checks); });
      var completed = stats.filter(function (s) { return s.complete; }).length;
      var totalItems = 0, doneItems = 0, scored = 0, goodSum = 0;
      stats.forEach(function (s) {
        totalItems += s.total; doneItems += s.done;
        if (s.score !== null) { scored++; goodSum += s.score; }
      });

      var top = el("div", "nb-dash__top");
      var pct = totalItems ? Math.round((100 * doneItems) / totalItems) : 0;
      top.innerHTML =
        '<div class="nb-dash__stat"><span class="nb-dash__num">' + completed + "/" + lessons.length + '</span><span class="nb-dash__lbl">lessons complete</span></div>' +
        '<div class="nb-dash__stat"><span class="nb-dash__num">' + pct + '%</span><span class="nb-dash__lbl">activities done</span></div>' +
        '<div class="nb-dash__stat"><span class="nb-dash__num">' + (scored ? Math.round(goodSum / scored) + "%" : "–") + '</span><span class="nb-dash__lbl">average first-try score</span></div>';
      host.appendChild(top);
      host.appendChild(el("div", "nb-bar nb-bar--big", '<span style="width:' + pct + '%"></span>'));

      var nextLesson = null;
      lessons.forEach(function (l, i) { if (!nextLesson && !stats[i].complete) nextLesson = l; });
      var cont = el("p", "nb-dash__continue");
      cont.innerHTML = nextLesson
        ? '<a class="md-button md-button--primary" href="' + asset(nextLesson.url) + '">Continue: ' + esc(nextLesson.title) + " →</a>"
        : "Every lesson written so far is complete. Ask Claude for the next module! 🎉";
      host.appendChild(cont);

      host.appendChild(text("h2", "", "Lessons"));
      var tbl = el("table", "nb-dash__table");
      tbl.innerHTML = "<thead><tr><th>Lesson</th><th>Status</th><th>Activities</th><th>First-try score</th></tr></thead>";
      var tb = el("tbody");
      var lastModule = null;
      lessons.forEach(function (l, i) {
        var s = stats[i];
        if (l.module !== lastModule) {
          lastModule = l.module;
          var mrow = el("tr", "nb-dash__module");
          mrow.innerHTML = '<td colspan="4">Level ' + l.level + " · Module " + l.module + "</td>";
          tb.appendChild(mrow);
        }
        var status = s.complete ? '<span class="nb-pill nb-pill--done">✓ Complete</span>'
          : s.started ? '<span class="nb-pill nb-pill--doing">In progress</span>'
          : '<span class="nb-pill">Not started</span>';
        var tr = el("tr");
        var p = s.total ? Math.round((100 * s.done) / s.total) : 0;
        tr.innerHTML = '<td><a href="' + asset(l.url) + '">' + esc(l.title) + "</a></td><td>" + status + "</td>" +
          '<td><div class="nb-bar nb-bar--small"><span style="width:' + p + '%"></span></div>' + s.done + "/" + s.total + "</td>" +
          "<td>" + (s.score !== null ? s.score + "%" : "–") + "</td>";
        tb.appendChild(tr);
      });
      tbl.appendChild(tb);
      host.appendChild(tbl);

      host.appendChild(text("h2", "", "Concepts to review"));
      var review = [];
      stats.forEach(function (s) { review = review.concat(s.review); });
      if (!review.length) {
        host.appendChild(text("p", "", "Nothing flagged yet. Questions you miss or rate as Partly/Missed will appear here with a link back."));
      } else {
        var byConcept = {};
        review.forEach(function (r) {
          var c = r.item.concept || "general";
          (byConcept[c] = byConcept[c] || []).push(r);
        });
        var ul = el("ul", "nb-dash__review");
        Object.keys(byConcept).sort().forEach(function (c) {
          var li = el("li");
          li.innerHTML = "<strong>" + esc(c.replace(/-/g, " ")) + "</strong>: " + byConcept[c].map(function (r) {
            return '<a href="' + asset(r.lesson.url) + "#q-" + esc(r.item.id) + '">' + esc(r.item.id) + "</a>";
          }).join(", ");
          ul.appendChild(li);
        });
        host.appendChild(ul);
      }

      host.appendChild(text("h2", "", "Checker results"));
      var ids = Object.keys(checks);
      if (!ids.length) host.appendChild(text("p", "", "No checker scripts run yet."));
      else {
        var cl = el("ul");
        ids.sort().forEach(function (id) {
          var r = checks[id];
          var li = el("li");
          li.innerHTML = (r.passed ? "✅ " : "❌ ") + "<code>" + esc(id) + "</code> · " + esc(when(r.timestamp)) +
            (r.info ? " · " + esc(r.info) : "");
          cl.appendChild(li);
        });
        host.appendChild(cl);
      }

      host.appendChild(text("h2", "", "Back up or move your progress"));
      host.appendChild(el("p", "",
        "Your answers are saved in <strong>this browser</strong> for this site address (" + esc(window.location.host || "local file") +
        "). Export a backup now and then, especially before clearing browser data or switching browsers. Checker results live in the <code>progress/checks/</code> folder of your project."));
      var tools = el("div", "nb-dash__tools");
      var exp = btn("Export progress"), imp = btn("Import progress"), rst = btn("Reset all answers", "nbq__btn--danger");
      var file = document.createElement("input"); file.type = "file"; file.accept = "application/json"; file.hidden = true;
      exp.addEventListener("click", function () {
        var blob = new Blob([JSON.stringify(load(), null, 1)], { type: "application/json" });
        var a = document.createElement("a");
        a.href = URL.createObjectURL(blob);
        a.download = "nextflow-course-progress-" + new Date().toISOString().slice(0, 10) + ".json";
        document.body.appendChild(a); a.click(); a.remove();
      });
      imp.addEventListener("click", function () { file.click(); });
      file.addEventListener("change", function () {
        var f = file.files && file.files[0];
        if (!f) return;
        f.text().then(function (t) {
          var s = JSON.parse(t);
          if (!s || s.v !== 1 || !s.items) throw new Error("not a progress file");
          save(s); renderDashboard(host);
        }).catch(function () { alert("That file doesn't look like a progress export."); });
      });
      rst.addEventListener("click", function () {
        if (confirm("Erase all your saved answers in this browser? Checker results are not affected.")) {
          try { window.localStorage.removeItem(KEY); } catch (e) { /* ignore */ }
          renderDashboard(host);
        }
      });
      [exp, imp, rst, file].forEach(function (b) { tools.appendChild(b); });
      host.appendChild(tools);
    });
  }

  /* ---------- init (runs on every instant-navigation page load) ------------ */
  function init() {
    var state = load();
    var lessonNode = document.querySelector(".nb-lesson-progress");
    if (lessonNode) {
      state.visited = state.visited || {};
      if (!state.visited[lessonNode.dataset.lesson]) { state.visited[lessonNode.dataset.lesson] = new Date().toISOString(); save(state); }
    }
    Array.prototype.forEach.call(document.querySelectorAll(".nbq"), function (n) { renderWidget(n, state); });
    refreshLessonBars();
    var dash = document.getElementById("nb-dashboard");
    if (dash) renderDashboard(dash);
  }

  if (window.document$ && typeof window.document$.subscribe === "function") {
    window.document$.subscribe(function () { checksPromise = null; init(); });
  } else if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }

  window.NFCourse = { load: load, save: save, KEY: KEY };
})();
