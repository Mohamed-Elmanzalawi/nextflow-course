---
lesson: "2.4"
module: 2
level: 1
---

# Lesson 2.4: Your workbench: VS Code + Nextflow extension, and Git

!!! info "About this lesson"
    **You'll learn:**

    - how to set up VS Code to catch Nextflow mistakes **as you type**;
    - how to put this course folder under **Git** version control;
    - what belongs in a pipeline repository, and what never does.

    **Why it matters:** the editor turns cryptic run-time errors into red squiggles before you even run anything. Git is the "**same code**" pillar of reproducibility from Lesson 1.2: every result can point to an exact version of the pipeline.

    **Time:** about 1 h · **Level:** Beginner · **Needs:** VS Code, Git

    **Docs:** [VS Code integration](https://docs.seqera.io/nextflow/vscode) · [Extension on the Marketplace](https://marketplace.visualstudio.com/items?itemName=nextflow.nextflow) · [Pro Git book (free)](https://git-scm.com/book/en/v2)

!!! flo "Flo says"
    Last lesson of Module 2! After this, your setup is complete. From Module 3 on, we write real pipelines in VS Code and save every step with Git.

---

## A. Concept

### The Nextflow extension for VS Code

You're already reading this course in VS Code. The official **Nextflow extension** (`nextflow.nextflow`) uses the Nextflow **language server**, a helper program that understands Nextflow code, to give you:

| Feature | What it does for you |
|---|---|
| Syntax highlighting | Processes, channels and strings in colour |
| **Diagnostics** | Errors and warnings underlined **as you type**, using the same strict-syntax rules as `nextflow lint` |
| Hover hints | Hover over an operator or directive to see its documentation |
| Code navigation | Outline, go to definition, find references |
| Completion, formatting, rename | The usual editor comforts |
| **DAG preview** | Draws a workflow's graph, like Lesson 1.2's diagram, from your code |

On Apple Silicon the extension brings **its own Java**, so it works whatever Java you've installed.

!!! funfact "Fun fact"
    Since Nextflow 26.04, the **strict syntax** parser is the default. It's stricter about code style, and its errors are clearer. The VS Code extension and `nextflow lint` use the same rules, so if the editor is happy, `nextflow run` will be too. Docs: [strict syntax](https://docs.seqera.io/nextflow/strict-syntax).

### Git in one table

You may already use Git. Here's what matters for pipelines:

| Command | What it does |
|---|---|
| `git init` | Turn the current folder into a repository |
| `git status` | What's changed, new, or staged |
| `git add <files>` | **Stage** changes for the next snapshot |
| `git commit -m "message"` | Save a **snapshot** (a commit) with a message |
| `git log --oneline` | History of snapshots |
| `git tag v0.1` | Give the current snapshot a **permanent name**, e.g. a release |
| `.gitignore` | A file listing patterns Git should **never** track |

!!! analogy "Real-life analogy: a lab notebook"
    - A **commit** is a dated, signed notebook entry.
    - A **tag** is a sticky tab on an important page ("version used for the paper").
    - `.gitignore` is the rule "don't glue raw instrument output into the notebook". It's kept elsewhere.

### What goes in a pipeline repository?

| ✅ Commit | ❌ Never commit (add to `.gitignore`) |
|---|---|
| `main.nf`, `modules/`, `nextflow.config` | `work/`: task folders, often **huge** |
| Small test data (KB to a few MB) | `.nextflow/` and `.nextflow.log*`: run history and logs |
| `README.md`, docs, samplesheet templates | `results/`: outputs; rebuild them from the code |
| Checker and test scripts | Big raw data (FASTQ/BAM): keep it on storage, not in Git |

This course already has a `.gitignore` set up this way:

```text title=".gitignore"
--8<-- ".gitignore"
```

!!! gotcha "Gotcha! `git add .` in a folder that has run a pipeline"
    If `work/` isn't ignored, `git add .` will try to add **thousands of files and gigabytes** of intermediate data. Always set up `.gitignore` **before** your first run, and glance at `git status` before every commit.

---

## B. Demonstration

### 1. Install the extension

```bash title="Terminal"
code --install-extension nextflow.nextflow
code --list-extensions | grep -i nextflow
```

You should see `nextflow.nextflow`. You can also install it from the Extensions panel in VS Code (search "Nextflow").

### 2. See it catch a mistake

Open `module02_environment/lesson03_containers/main.nf` in VS Code. Change `process` on line 1 to `proces`, then look at the line and the **Problems** panel (++cmd+shift+m++). Undo the change afterwards.

??? predict "Predict: what will the error say?"
    The same check from the terminal, `nextflow lint` on the broken file (real output, Nextflow 26.10.7):

    ```text title="Real output"
    Error broken.nf:1:1: Statements cannot be mixed with script declarations -- move statements into a process, workflow, or function
    │   1 | proces FASTQC_VERSION {
    │     | ^^^^^^^^^^^^^^^^^^^^^^^
    ```

    Nextflow no longer recognises `proces` as a keyword, so it reads the line as a stray statement. Error messages often describe the **symptom**, so look at the exact spot they point to.

### 3. Put the course under Git

```bash title="Terminal"
cd "$COURSE"
git init -b main
git status                       # notice: no site/, work/ or data/ folders listed
git add .
git commit -m "Course setup: modules 1-2"
git log --oneline
```

!!! note "Did you `git clone` the course?"
    Then the folder is already a repository with the course's history. Skip `git init`, run `git status` and `git log --oneline` to look around, and commit your own changes as you work through the lessons.

??? predict "Predict: will `site/` (the built website) appear in `git status`?"
    No. `site/` is in `.gitignore`, because it's **generated** from `docs/` by `mkdocs build`, just as `work/` is generated by `nextflow run`. Commit the source, not the generated output.

---

## C. Walkthrough: reading `git status`

| `git status` section | Meaning |
|---|---|
| *Untracked files* | Files Git has never seen; `git add` them to start tracking |
| *Changes not staged for commit* | Tracked files you've edited but not staged |
| *Changes to be committed* | Staged and ready for `git commit` |
| *(nothing listed)* | Matches the last commit, or is ignored by `.gitignore` |

`git check-ignore -v <path>` tells you **which** `.gitignore` rule ignores a file. That's handy when something is ignored and you don't know why.

!!! protip "Pro tip: commit small, commit often"
    One logical change per commit, with a message saying **why** ("Add fastp trimming step", not "update"). When a run suddenly behaves differently, `git log` and `git diff` show you exactly what changed.

---

## D. Guided exercise (about 25 min)

```quiz
id: 2.4-ex-steps
type: steps
concept: version-control
label: "Mission steps"
steps:
  - "Install the Nextflow extension and confirm it with `code --list-extensions`."
  - "Break line 1 of the Lesson 2.3 `main.nf` (`proces`), see the error in VS Code, then undo it."
  - "Run `git init -b main` in the course folder, check `git status`, and make your **first commit**."
  - |
    Prove the ignore rules work:

    ```bash
    git check-ignore -v work/anything .nextflow.log site/index.html
    ```
```

```quiz
id: 2.4-ex-a
type: single
concept: version-control
question: "`git check-ignore -v work/anything` printed a line. What does it tell you?"
options:
  - text: "That `work/anything` was deleted."
  - text: "Which `.gitignore` file and **line** ignores that path (here, the `work/` rule)."
    correct: true
  - text: "That Git is broken."
explain: "`-v` (verbose) shows the source file, line number and pattern that matched. It's perfect for debugging \"why isn't this file showing up?\""
```

```quiz
id: 2.4-ex-b
type: multi
concept: version-control
question: "Which of these belong **in** the Git repository of a Nextflow pipeline? Tick all that apply."
options:
  - text: "`main.nf` and `nextflow.config`"
    correct: true
  - text: "A 3 MB test FASTQ used by the pipeline's tests"
    correct: true
  - text: "`work/` after a run"
  - text: "`.nextflow.log`"
  - text: "A 40 GB BAM file"
explain: "Code, config, docs and **small** test data go in Git. Runtime folders (`work/`, `.nextflow*`), results and big data stay out. Big data lives on your storage or the cluster, and the pipeline points to it with parameters."
```

---

## E. Independent challenge: a tagged milestone

1. Make a **second commit**: for example, add a `NOTES.md` with what you learned in Module 2.
2. Mark this point in history with a **tag** called `module-2-done`.
3. Run the checker. It checks the extension, your repository, the ignore rules, and the tag.

```quiz
id: 2.4-git
type: check
concept: version-control
label: "Challenge: auto-checked"
check: 2.4-git
command: "bash check_git.sh"
hint: "`git tag <name>` tags the current commit. `git tag` (no arguments) lists tags. Run the checker from `module02_environment/lesson04_vscode_git`."
explain: "A tag is a permanent, human-friendly name for a commit. Pipelines publish releases as tags (`v1.0.0`), and `nextflow run <org>/<repo> -r v1.0.0` runs **exactly** that release, as you saw with `hello -r v1.3` in Lesson 2.2."
```

```quiz
id: 2.4-ch-q
type: open
concept: version-control
question: "Six months from now a reviewer asks: *\"Which version of your pipeline produced Figure 3?\"* How do Git commits/tags and Nextflow together let you answer precisely?"
model: "Tag the exact pipeline version used (e.g. `v1.2.0`) and record it with the results. Nextflow shows the code's revision for each run (`nextflow log` has a **revision ID** column), and `nextflow run <repo> -r v1.2.0` reruns exactly that code. Together with pinned containers (Lesson 2.3) and `NXF_VER` (Lesson 2.2), code, software and Nextflow itself are all pinned."
```

---

## F. Knowledge check

```quiz
id: 2.4-q1
type: single
concept: version-control
question: "You run a pipeline, then `git add .` in a repo **without** a `.gitignore`. What's the main risk?"
options:
  - text: "Git refuses to add anything."
  - text: "You stage `work/`, `.nextflow/` and results: potentially thousands of files and gigabytes."
    correct: true
  - text: "Nextflow deletes your results."
explain: "Ignore runtime and generated files from the start, and check `git status` before committing."
```

```quiz
id: 2.4-q2
type: single
concept: editor
question: "The VS Code extension underlines an error in `main.nf`. Which command checks the same rules from the terminal (handy on your cluster, where you have no VS Code)?"
options:
  - text: "`nextflow info`"
  - text: "`nextflow lint main.nf`"
    correct: true
  - text: "`nextflow log`"
explain: "`nextflow lint` runs the same language-server checks from the command line. Since 26.04 the strict syntax is the default, so lint errors are real run errors."
```

---

## G. Summary

| Command | What it does |
|---|---|
| `code --install-extension nextflow.nextflow` | Install the Nextflow VS Code extension |
| `nextflow lint main.nf` | Check Nextflow code from the terminal |
| `git init -b main` | Start a repository (branch `main`) |
| `git status` / `git add` / `git commit -m` | See changes / stage / snapshot |
| `git log --oneline` | History |
| `git tag name` | Name a commit permanently |
| `git check-ignore -v path` | Which rule ignores a path |

**Module 2 complete.** Your setup now covers Java, Nextflow, Docker, conda, an Apptainer profile ready for your cluster, an editor with diagnostics, and version control. Module 3 is where you write your first pipeline.

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="2.4"></div>
