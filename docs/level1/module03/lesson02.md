---
lesson: "3.2"
module: 3
level: 1
---

# Lesson 3.2: Processes and workflows: your first real pipeline

!!! info "About this lesson"
    **You'll learn:**

    - how a process takes **files** as input (`path`), and what "staging" means;
    - how calling a process on a channel creates **one task per item**, in parallel;
    - how processes are **chained**: the output channel of one is the input of the next;
    - how `collect()` gathers many results into one task.

    **Why it matters:** this is the pattern behind every Nextflow pipeline. "Run step A on every sample, then combine the results" covers FastQC → MultiQC, alignment → variant calling, quantification → a count matrix, and so on.

    **Time:** about 1 h · **Level:** Beginner · **Needs:** Lesson 3.1

    **Docs:** [Processes: inputs](https://docs.seqera.io/nextflow/process#inputs) · [Workflows](https://docs.seqera.io/nextflow/workflow) · [`collect`](https://docs.seqera.io/nextflow/reference/operator#collect)

!!! flo "Flo says"
    Remember the Nextflow preview in Lesson 1.1, the one you were told to "read, not memorise"? Today you run it. By the end of this lesson every line will make sense.

---

## A. Concept

### A process that works on files

```groovy title="main.nf"
--8<-- "module03_first_pipeline/lesson02_processes_workflows/main.nf"
```

Three new ideas, all in this file:

**1. `input: path fq`.** Each task receives **one file**, and Nextflow **stages** it: it puts a symbolic link to the file into the task's own folder (you saw this in the Lesson 2.1 animation). Inside the script you refer to it by its variable name, `${fq}`. `${fq.baseName}` is the name without the extension: `sample1.fastq` → `sample1`.

**2. A process call returns a channel.** `counts_ch = COUNT_READS(reads_ch)` doesn't return "the result". It returns a **channel** that will deliver the results, one per task, as they finish. You pass that channel on to the next process. That's how processes are chained.

**3. `collect()` turns many items into one.** `counts_ch` delivers three count files, one by one. `counts_ch.collect()` waits until the channel has delivered **all** of them, then emits a single list. So `SUMMARISE` runs **once**, with all three files, and can't start too early.

| Line in `workflow { }` | Python equivalent |
|---|---|
| `reads_ch = channel.fromPath('data/*.fastq')` | `reads = glob.glob('data/*.fastq')` |
| `counts_ch = COUNT_READS(reads_ch)` | `counts = [count_reads(f) for f in reads]`, but in **parallel** |
| `summary_ch = SUMMARISE(counts_ch.collect())` | `summary = summarise(counts)` |
| `summary_ch.view()` | `print(summary)` |

--8<-- "includes/anim/workflow_wiring.html"

!!! analogy "Real-life analogy: a sample-prep bench"
    `channel.fromPath` is the rack of tubes arriving at the bench. `COUNT_READS` is a step that **every** tube goes through, on as many benches as you have free. `collect()` is waiting until the whole rack is done before the plate goes into the reader (`SUMMARISE`).

---

## B. Demonstration

```bash title="Terminal"
cd ~/Desktop/Projects/learning_nextflow/module03_first_pipeline/lesson02_processes_workflows
bash ../make_data.sh          # 3 small FASTQ files in data/
nextflow run main.nf
```

??? predict "Predict: each COUNT_READS task sleeps 2 seconds. How long does the whole run take with 3 samples?"
    Real output (Nextflow 26.10.7, 12-core Mac):

    ```text title="Real output"
    Created 3 new FASTQ file(s) in data/ (kept 0 existing)

     N E X T F L O W   ~  version 26.10.7

    Launching `main.nf` [lonely_kalman] revision: 0ec322069d

    executor >  local (4)
    [95/3982b5] COUNT_READS (2) | 3 of 3 ✔
    [16/394e36] SUMMARISE       | 1 of 1 ✔
    …/lesson02_processes_workflows/work/16/394e3608159a917ca26c39d9ac8670/summary.tsv
    ```

    (The last line is one long path; it's shortened here.) The whole run took about **4 seconds**, including Nextflow's own start-up: the three 2-second tasks ran **at the same time**. In Lesson 1.1 the Bash loop needed 2 s × 3 = 6 s for the same work.

The last line comes from `summary_ch.view()`: it printed the path of the summary file. Look inside, using **your** path:

```bash title="Terminal"
cat work/16/394e36*/summary.tsv
```

```text title="Real output"
sample1	1000
sample2	1250
sample3	1500
```

`make_data.sh` gives each sample a different number of reads (and a different GC content, which you'll need in the challenge).

---

## C. Code walkthrough

### What Bash actually ran

Open the folder of the `sample1` task (find it with `find work -name sample1.count.tsv`):

```text title="work/a9/faa7b2…/.command.sh (real)"
#!/bin/bash -ue
sleep 2
awk -v s=sample1 'END { print s "\t" NR / 4 }' sample1.fastq > sample1.count.tsv
```

```text title="ls -l work/a9/faa7b2… (real, path shortened)"
-rw-r--r--  1 mohamed  wheel   13 Nov 26 12:04 sample1.count.tsv
lrwxr-xr-x  1 mohamed  wheel  180 Nov 26 12:04 sample1.fastq -> …/lesson02_processes_workflows/data/sample1.fastq
```

Compare with the script block in `main.nf`:

| In `main.nf` | In `.command.sh` | Why |
|---|---|---|
| `${fq.baseName}` | `sample1` | Nextflow filled in the value **before** Bash ran |
| `${fq}` | `sample1.fastq` | Just the file name: the file is linked into the task folder |
| `"\\t"` | `"\t"` | Nextflow's string turns `\\` into one `\`, so `awk` receives its usual `\t` |

!!! gotcha "Gotcha! Two languages in one block"
    Inside `"""…"""`, **Nextflow** reads the text first and replaces every `${…}`. Only then does **Bash** run it. So a Bash variable like `$HOME` or awk's `$0` must be written as `\$HOME` and `\$0`, or Nextflow tries to fill it in itself. Lesson 4.1 is all about this; for now, remember the rule: **`$` that belongs to Bash or awk gets a backslash.**

### Why the summary order can change

`collect()` gathers the count files in the order the tasks **finish**, not in file-name order. On another run, `sample2` might come first. If order matters, sort explicitly (you'll do that in Lesson 3.3).

### How many tasks at once?

On your computer, the `local` executor runs as many tasks at the same time as you have CPU cores (Nextflow checks). The test machine has 12, so even 10 samples finish in one "wave":

```bash title="Terminal"
bash ../make_data.sh 10        # adds sample4 … sample10
time nextflow run main.nf
```

On the 12-core test Mac this also took about **4 seconds**. On a Mac with fewer cores, some tasks wait for a free core, so expect a little longer. On your SLURM cluster, the limit is the queue, not your laptop.

!!! protip "Pro tip: name channels with `_ch`"
    `reads_ch`, `counts_ch`, `summary_ch`: the suffix reminds you that the variable holds a **channel** (a stream of future values), not a file or a list. nf-core pipelines use the same habit (`ch_reads`).

---

## D. Guided exercise (about 25 min)

```quiz
id: 3.2-ex-steps
type: steps
concept: processes
label: "Mission steps"
steps:
  - "Create the data with `bash ../make_data.sh` and run `main.nf`."
  - "Open the summary file using the path printed by `view()`."
  - "Open one `COUNT_READS` task folder: read `.command.sh` and run `ls -l` to see the linked FASTQ file."
  - "Run `bash ../make_data.sh 10` and time the run with 10 samples."
  - "Run `nextflow run main.nf -ansi-log false` and count the `COUNT_READS` lines."
```

```quiz
id: 3.2-ex-a
type: number
concept: processes
question: "With 10 samples, how many tasks does one run of `main.nf` start **in total** (all processes)?"
answer: 11
tolerance: 0
unit: tasks
explain: "10 `COUNT_READS` tasks (one per file) + 1 `SUMMARISE` task (it receives the collected list once) = 11. The console shows `executor > local (11)`."
```

```quiz
id: 3.2-ex-b
type: single
concept: staging
question: "In the task folder, `sample1.fastq` is a symbolic link. Why doesn't Nextflow copy the file?"
options:
  - text: "Copying is not allowed on macOS."
  - text: "A link costs no time or disk space, even for a 50 GB BAM file; the task still reads the original."
    correct: true
  - text: "So that the task can modify the original file."
explain: "Staging by link is fast and free. (Tasks should **never** modify their inputs, though: treat them as read-only.)"
```

```quiz
id: 3.2-ex-c
type: single
concept: collect
question: "What would happen if you removed `.collect()` and wrote `SUMMARISE(counts_ch)`?"
options:
  - text: "Exactly the same result."
  - text: "SUMMARISE would run **once per sample**, each time with a single count file, giving 3 one-line summaries."
    correct: true
  - text: "Nextflow would refuse to run."
explain: "Without `collect()`, `counts_ch` still delivers 3 separate items, so `SUMMARISE` gets 3 separate tasks. `collect()` is what turns \"many items\" into \"one list\". Try it, and look at the console: `SUMMARISE | 3 of 3`."
```

---

## E. Independent challenge

Copy `main.nf` to **`gc.nf`** and extend it with a second branch that measures **GC content**:

- a new process **`GC_CONTENT`**: for each FASTQ file, write `<sample>.gc.tsv` with one line: the sample name, a tab, and the **percentage of G and C bases** in the sequence lines, with 2 decimals (for example `sample1	30.34`);
- a new process **`GC_SUMMARY`**: takes **all** the GC files at once and writes them, **sorted**, to `gc_summary.tsv`;
- `COUNT_READS` and `SUMMARISE` must keep working as before. Both branches read the **same** `reads_ch`.

The checker runs your `gc.nf` on **4 fresh samples** and compares every percentage with its own calculation.

```quiz
id: 3.2-challenge
type: check
concept: processes
label: "Challenge: auto-checked"
check: 3.2-challenge
command: "bash check_gc.sh"
solution: includes/solutions/3.2/gc.nf
hint: |
  In a FASTQ file the sequence is every 4th line, starting at line 2: in awk, `NR % 4 == 2`. `gsub(/[GC]/, "")` returns how many G/C characters it removed, and `length($0)` gives the line length (take the length **before** calling `gsub`). Inside the script block, awk's `$0` must be written `\$0`, `\t` as `\\t` and `\n` as `\\n`. To print 2 decimals: `printf "%s\\t%.2f\\n", s, value`.
explain: "Using one channel for two processes is fine: each process gets its own copy of every item. That's how a real pipeline runs FastQC and trimming on the same reads at the same time."
```

---

## F. Knowledge check

```quiz
id: 3.2-q1
type: single
concept: channels
question: "What does `counts_ch = COUNT_READS(reads_ch)` store in `counts_ch`?"
options:
  - text: "The finished count files, after all tasks are done."
  - text: "A channel that will deliver each task's output as it finishes."
    correct: true
  - text: "The exit code of the last task."
explain: "Calling a process **wires** it into the flow and returns its output channel. Nothing has run yet at that moment."
```

```quiz
id: 3.2-q2
type: open
concept: dataflow
question: "Nowhere in `main.nf` is there a loop or a \"wait\". Explain how Nextflow still knows to run three `COUNT_READS` tasks, and to start `SUMMARISE` only at the end."
model: "Each item in `reads_ch` creates one `COUNT_READS` task: three files, three tasks. `SUMMARISE` receives `counts_ch.collect()`, which emits its single list only after `counts_ch` has delivered every count, so `SUMMARISE` simply has no input until all counting is done. The order comes from the **data dependencies**, not from the order of lines."
explain: "This is the dataflow model from Lesson 1.2, now in real code."
```

```quiz
id: 3.2-q3
type: single
concept: interpolation
question: "Inside a `script:` block you want awk to print the whole line, `$0`. What do you write?"
options:
  - text: "`$0`"
  - text: "`\\$0`"
    correct: true
  - text: "`${0}`"
explain: "A bare `$` would be read by Nextflow first. The backslash tells Nextflow \"leave this `$` for Bash/awk\"."
```

```quiz
id: 3.2-q4
type: single
concept: collect
question: "Why might `summary.tsv` list `sample2` before `sample1`?"
options:
  - text: "Because of a bug in `collect()`."
  - text: "`collect()` keeps the order in which tasks **finished**, and parallel tasks can finish in any order."
    correct: true
  - text: "Because Nextflow sorts by file size."
explain: "Parallel means \"no guaranteed order\". Sort explicitly when you need a stable order."
```

---

## G. Summary

| Concept | Remember |
|---|---|
| `path` input | One file per task, **staged** as a link into the task folder |
| Process call | Returns a **channel** of outputs; pass it to the next process |
| One item → one task | All tasks of a process run in parallel, up to your CPU count |
| `collect()` | Waits for every item, emits **one** list → the next process runs once |
| `view()` | Prints every item a channel delivers |
| Two languages | `${…}` = Nextflow; a `$` for Bash/awk needs a backslash `\$` |

Next: in **Lesson 3.3** you'll make the input files configurable with **parameters**, and put the results somewhere better than `work/`.

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="3.2"></div>
