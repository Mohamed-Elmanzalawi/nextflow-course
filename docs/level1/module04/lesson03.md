---
lesson: "4.3"
module: 4
level: 1
---

# Lesson 4.3: Task isolation and debugging failed tasks

!!! info "About this lesson"
    **You'll learn:**

    - why each task can only see **its own folder**, and what that means for helper scripts;
    - how to read Nextflow's **error report**;
    - the **debugging loop**: from the report to the task folder, `.command.err`, `bash .command.run`, and back with `-resume`;
    - how to stop pipes from hiding failures, for every task at once.

    **Why it matters:** tasks *will* fail: a missing file, a typo, a tool that crashed. People who can debug a failed task in two minutes are the ones who get pipelines into production.

    **Time:** about 1.5 h · **Level:** Beginner · **Needs:** Lessons 2.1 and 4.2

    **Docs:** [`errorStrategy`](https://docs.seqera.io/nextflow/reference/process/directives/error-strategy) · [The `bin` directory](https://docs.seqera.io/nextflow/sharing#the-bin-directory) · [`process.shell`](https://docs.seqera.io/nextflow/reference/process/directives/shell)

!!! flo "Flo says"
    Every task runs alone in its own folder. That's what makes Nextflow reproducible and resumable, and it's also the cause of a whole family of beginner errors. Today you learn to see the world from inside a task.

---

## A. Concept

### A task only sees its own folder

When a task runs, its current folder is `work/xx/yyyy…`. In that folder there are:

- its **inputs**, staged as links;
- its generated scripts (`.command.sh`, `.command.run`);
- whatever it creates.

There is **no** copy of your project. A command like `bash scripts/helper.sh` looks for `work/xx/yyyy…/scripts/helper.sh`, which doesn't exist. Two ways to give a task access to a helper script:

| Way | How | When |
|---|---|---|
| **`bin/` folder** | Put the script in `bin/` next to `main.nf` and make it executable (`chmod +x`). Nextflow adds `bin/` to every task's `PATH`, so you call it by name: `mean_length.sh …` | The standard way; works with containers and on clusters |
| `${projectDir}` | `bash ${projectDir}/scripts/helper.sh …`. `projectDir` is the folder containing `main.nf` | Quick fixes |

### The error report

When a task fails, Nextflow prints a report with everything you need to start:

| Part | Tells you |
|---|---|
| `Error executing process > 'NAME (tag)'` | **Which** task failed |
| `Caused by:` | **Why**, in Nextflow's words: an exit status, a missing output, a time limit… |
| `Command executed:` | The script, with every `${…}` already filled in |
| `Command exit status:` | The exit code (0, 1, 127, 137, …: Lesson 2.1) |
| `Command output:` / `Command error:` | The last lines of `.command.out` and `.command.err` |
| `Work dir:` | **Where** to go next |

### The debugging loop

--8<-- "includes/anim/debug_loop.html"

---

## B. Demonstration: a failure that hides

```groovy title="hidden_failure.nf"
--8<-- "module04_processes/lesson03_task_isolation/hidden_failure.nf"
```

`data/sample1.fastq` is **not** gzipped, so `gzip -cd` can't read it.

```bash title="Terminal"
cd ~/Desktop/Projects/learning_nextflow/module04_processes/lesson03_task_isolation
bash ../make_data.sh                  # plain .fastq files
bash ../make_data.sh 3 1000 data gz   # and .fastq.gz files, for the challenge
nextflow run hidden_failure.nf
```

??? predict "Predict: will the task fail?"
    Real output:

    ```text title="Real output"
    executor >  local (1)
    [be/b4129b] FIRST_READ (1) | 1 of 1 ✔
    ```

    A ✔! But look inside the task folder:

    | In `work/be/b4129b…` (real values) | |
    |---|---|
    | `first_read.txt` | 0 bytes |
    | `.exitcode` | `0` |
    | `.command.err` | `gzip: can't stat: sample1.fastq (sample1.fastq.gz): No such file or directory` |

    `gzip` failed, but `head` (the last command of the pipe) succeeded, so the task's exit code was 0. This is the Lesson 2.1 `pipefail` problem, now inside Nextflow. The declared output exists (empty), so Nextflow had no reason to complain.

### Turn on `pipefail` for every task

```groovy title="nextflow.config"
process.shell = ['/bin/bash', '-euo', 'pipefail']
```

With that line, every task's `.command.sh` starts with `#!/bin/bash -euo pipefail` instead of `#!/bin/bash -ue`, and a failure anywhere in a pipe fails the task. On a test pipeline with the same bug, the report then said:

```text title="Real output (part)"
Caused by:
  Process `GC (1)` terminated with an error exit status (1)

Command error:
  gzip: reads.fastq: not in gzip format
```

!!! gotcha "Gotcha! Changing `process.shell` doesn't re-run cached tasks"
    The shell setting is **not** part of the task hash (Lesson 3.4). In a test, adding `pipefail` and running with `-resume` took every task, including the silently broken one, **from the cache**. After changing `process.shell`, run once **without** `-resume`.

---

## C. Code walkthrough: the loop, step by step

This is the challenge pipeline, `qc.nf`, after its first bug was fixed. `MEAN_LENGTH` calls a helper script:

```groovy title="qc.nf (part)"
    script:
    """
    bash scripts/mean_length.sh ${fq} > ${fq.simpleName}.length.tsv
    """
```

**① Read the report.**

```text title="Real output"
Caused by:
  Process `MEAN_LENGTH (3)` terminated with an error exit status (127)

Command executed:

  bash scripts/mean_length.sh sample3.fastq.gz > sample3.length.tsv

Command exit status:
  127

Command error:
  bash: scripts/mean_length.sh: No such file or directory

Work dir:
  …/lesson03_task_isolation/work/e4/4e50a612e14a425cf5eee844ae395e
```

Exit status 127 means "command not found" (Lesson 2.1).

**② Go to the task folder, and ③ look around.**

```bash title="Terminal"
cd work/e4/4e50a6*
ls -a
cat .command.err
```

```text title="Real output: ls -a (another MEAN_LENGTH task, same story)"
.                       .command.log            .exitcode
..                      .command.out            sample2.fastq.gz
.command.begin          .command.run            sample2.length.tsv
.command.err            .command.sh
```

No `scripts/` folder in here: the task can only see its input and its own files.

**④ Re-run the task by hand.** `bash .command.run` runs the task again, in this folder, exactly as Nextflow did. It's the fastest way to test a fix: edit `.command.sh` here, re-run, repeat. (Changes made here are lost; they're only for testing.)

**⑤ Fix the pipeline and resume.** Here: move the helper into `bin/`, make it executable, and call it by name:

```bash title="Terminal"
cd ~/Desktop/Projects/learning_nextflow/module04_processes/lesson03_task_isolation
mkdir -p bin && mv scripts/mean_length.sh bin/ && chmod +x bin/mean_length.sh
# in qc.nf:  mean_length.sh ${fq} > ${fq.simpleName}.length.tsv
nextflow run qc.nf -resume
```

```text title="Real output"
executor >  local (4)
[de/4db440] READ_STATS (1)  | 3 of 3, cached: 3 ✔
[78/857514] MEAN_LENGTH (3) | 3 of 3 ✔
[4b/e07ed1] REPORT          | 1 of 1 ✔
```

`READ_STATS` came from the cache; only the fixed step and what followed it ran.

!!! gotcha "Gotcha! Forgot `chmod +x`?"
    A script in `bin/` without execute permission fails with: `.command.sh: line 2: …/bin/mean_length.sh: Permission denied` (exit status 1, from a real test). Git keeps the execute permission, so `chmod +x` once is enough.

!!! protip "Pro tip: give helper scripts their own safety net"
    `process.shell` only changes `.command.sh`. A helper script runs with its **own** first line, so start every helper with `#!/usr/bin/env bash` and `set -euo pipefail`.

---

## D. Guided exercise (about 30 min)

```quiz
id: 4.3-ex-steps
type: steps
concept: debugging
label: "Mission steps"
steps:
  - "Run `hidden_failure.nf`; open the task folder and read `.command.err` and `.exitcode`."
  - "Run `nextflow run qc.nf` and read the error report, part by part."
  - "Go to the failed task's work dir. Run `ls -a`, `cat .command.sh`, `cat .command.err`."
  - "Run `bash .command.run` in that folder and confirm you get the same error."
  - "Go back to the lesson folder (`cd -`) before you continue."
```

```quiz
id: 4.3-ex-a
type: single
concept: debugging
question: "The first error from `qc.nf` says *Missing output file(s) `sample3.stats.tsv`*, but the command exited with 0. What do you check first?"
options:
  - text: "The input data: it must be corrupt."
  - text: "`ls` in the task folder: which file did the script actually create, and does its name match the declared output?"
    correct: true
  - text: "The memory directive."
explain: "Exit status 0 + missing output almost always means a name mismatch between `output:` and what the script writes. The task folder shows you the real name."
```

```quiz
id: 4.3-ex-b
type: single
concept: task-isolation
question: "Why does `bash scripts/mean_length.sh` work in your terminal but fail inside a task?"
options:
  - text: "Tasks can't run Bash scripts."
  - text: "The task runs in its own folder under `work/`, which contains no `scripts/` folder."
    correct: true
  - text: "The script needs to be compiled first."
explain: "Relative paths are relative to the task folder. Use `bin/` (on the `PATH` of every task) or `${projectDir}`."
```

```quiz
id: 4.3-ex-c
type: number
concept: exit-codes
question: "Which exit status means \"command not found\"?"
answer: 127
tolerance: 0
explain: "127: the shell couldn't find the command or script. 137 and 143 mean the task was killed (Lesson 4.2)."
```

---

## E. Independent challenge

`qc.nf` reports read counts and mean read lengths for `data/*.fastq.gz`. It has **three bugs**:

1. one task **doesn't keep its promise** (output);
2. one task **can't find** something it needs;
3. one failure is **silent**: a **truncated** `.fastq.gz` is counted as if it were fine.

Fix the first two with the debugging loop, until `results/qc_report.tsv` looks right. For the third, simulate a download that broke halfway, and look at the report:

```bash title="Terminal"
head -c 15000 data/sample3.fastq.gz > data/broken.fastq.gz
nextflow run qc.nf -resume
cat results/qc_report.tsv          # what's wrong with the 'broken' line?
rm data/broken.fastq.gz            # tidy up when you're done
```

Then make the pipeline **fail** on such a file instead of reporting nonsense. The checker copies `qc.nf` together with your `nextflow.config`, `bin/` and `scripts/` (if they exist), runs it on good data, then on data with a truncated file.

```quiz
id: 4.3-challenge
type: check
concept: debugging
label: "Challenge: auto-checked"
check: 4.3-challenge
command: "bash check_qc.sh"
solution: includes/solutions/4.3/qc.nf
hint: "Bug 1: compare the `output:` file name with the file the script writes. Bug 2: section C. Bug 3: section B, the `nextflow.config` line, then run **without** `-resume`. A read count that isn't a whole number is a giveaway."
explain: "The reference solution has three parts: the fixed `qc.nf` (shown), the helper moved to `bin/mean_length.sh` (with `set -euo pipefail`), and a `nextflow.config` with `process.shell = ['/bin/bash', '-euo', 'pipefail']`."
```

---

## F. Knowledge check

```quiz
id: 4.3-q1
type: open
concept: debugging
question: "Describe the debugging loop for a failed task, in five short steps."
model: "1. Read the error report: which task, why (Caused by), exit status, error output. 2. Go to the Work dir it names. 3. Read `.command.sh` (what ran) and `.command.err` (what went wrong); `ls -a` to see what the task could see and produced. 4. Re-run it there with `bash .command.run` to test a fix. 5. Fix the pipeline (script, config, inputs) and run again with `-resume`."
explain: "Report → folder → files → re-run → fix and resume."
```

```quiz
id: 4.3-q2
type: single
concept: pipefail
question: "Why can a task with `gzip -cd file.gz | awk …` report wrong results with exit status 0?"
options:
  - text: "Because awk ignores errors."
  - text: "Without `pipefail`, a pipe's exit status is the **last** command's: `gzip` fails, `awk` succeeds on the partial data, and the task looks fine."
    correct: true
  - text: "Because Nextflow doesn't check exit statuses."
explain: "Set `process.shell = ['/bin/bash', '-euo', 'pipefail']` once in `nextflow.config`, and every task's pipes fail loudly."
```

```quiz
id: 4.3-q3
type: single
concept: task-isolation
question: "Where should a helper script used by a process live?"
options:
  - text: "Anywhere; tasks can see your whole home folder by relative path."
  - text: "In the pipeline's `bin/` folder, executable, called by its name."
    correct: true
  - text: "Copied into every `work/` folder by hand."
explain: "`bin/` is added to every task's `PATH`, and it works the same way with containers and on SLURM."
```

---

## G. Summary

| Concept | Remember |
|---|---|
| Task isolation | A task sees only its own folder: staged inputs + what it creates |
| Error report | Which task, why, command, exit status, error output, **Work dir** |
| Debugging loop | Report → work dir → `.command.sh` / `.command.err` → `bash .command.run` → fix → `-resume` |
| `bin/` | Helper scripts, executable, automatically on every task's `PATH` |
| `process.shell` | `['/bin/bash', '-euo', 'pipefail']` makes pipe failures fail the task |
| Not in the hash | Changing `process.shell` → run without `-resume` once |

| Exit status | Usual meaning |
|---|---|
| 1 | The command itself reported an error |
| 127 | Command or script not found |
| 137 / 143 | Killed: memory / time |

Next: **Lesson 4.4**: the last piece of a process, inputs and outputs in all their forms: `val` and `path`, globs, named outputs, and outputs that might not exist.

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="4.3"></div>
