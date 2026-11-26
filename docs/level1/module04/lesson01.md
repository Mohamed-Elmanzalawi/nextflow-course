---
lesson: "4.1"
module: 4
level: 1
---

# Lesson 4.1: The blocks of a process

!!! info "About this lesson"
    **You'll learn:**

    - every section a process can have: `input:`, `output:`, `script:`, `stub:` and `exec:`;
    - the most important rule in Nextflow scripting: **`${…}` belongs to Nextflow, `\$` belongs to Bash**;
    - how `-stub` lets you test a pipeline's wiring in seconds instead of hours.

    **Why it matters:** most "my process won't even start" errors come from mixing up the two languages inside a script block. And a stub run lets you check a 20-step pipeline before spending a single CPU-hour on it.

    **Time:** about 1.25 h · **Level:** Beginner · **Needs:** Module 3

    **Docs:** [Processes](https://docs.seqera.io/nextflow/process) · [Stub](https://docs.seqera.io/nextflow/process#stub) · [Strict syntax](https://docs.seqera.io/nextflow/strict-syntax)

!!! flo "Flo says"
    Module 3 got your first pipeline running. Module 4 opens up the process itself, one part at a time. Today: the sections, and the two languages that share every script block.

---

## A. Concept

### The sections of a process

```groovy title="blocks.nf"
--8<-- "module04_processes/lesson01_process_blocks/blocks.nf"
```

| Section | Job | Required? |
|---|---|---|
| `input:` | What each task receives: `val` (a value) or `path` (a staged file). Several lines = several inputs, given **in this order** when you call the process | No |
| `output:` | What each task promises to produce | No, but almost always present |
| `script:` | The Bash commands, in a `"""…"""` string | One of `script:` or `exec:` |
| `stub:` | Replacement commands for a **dry run** with `-stub`: usually just `touch` the outputs | No |
| `exec:` | Groovy code run **inside Nextflow**, not in Bash | Instead of `script:` |

Directives such as `cpus` or `tag` go **above** `input:`. They're the topic of Lesson 4.2.

### Two languages in one block

The `script:` block is a Nextflow string that **contains** a Bash script. Both languages use `$`:

--8<-- "includes/anim/interpolation.html"

| You write | Who handles it | Becomes, in `.command.sh` |
|---|---|---|
| `${fq}`, `${fq.baseName}`, `${min_len}` | **Nextflow**, before the task starts | `sample1.fastq`, `sample1`, `50` |
| `\$0`, `\$reads`, `\$(cmd)`, `\$BASH_VERSION` | Left alone by Nextflow; **Bash/awk** handles them while running | `$0`, `$reads`, `$(cmd)`, `$BASH_VERSION` |
| `\\t`, `\\n` | Nextflow turns `\\` into `\` | `\t`, `\n` (for awk or printf) |

Python analogy: the script block is like an **f-string that contains a shell script**. `{name}` is filled by Python, and if you want a literal brace you double it. Here `${…}` is filled by Nextflow, and a `$` meant for Bash gets a backslash.

!!! analogy "Real-life analogy: a form letter"
    A form letter has blanks like «NAME» that the office fills in before posting it. But the letter can also say "write your own answer here: ____", which is left for the reader. `${…}` is the office's blank; `\$` is the reader's.

---

## B. Demonstration

```bash title="Terminal"
cd ~/Desktop/Projects/learning_nextflow/module04_processes/lesson01_process_blocks
bash ../make_data.sh
nextflow run blocks.nf
```

```text title="Real output"
Created 3 new .fastq file(s) in data/ (kept 0 existing)

 N E X T F L O W   ~  version 26.10.7

Launching `blocks.nf` [admiring_woese] revision: 0fb2dfae35

executor >  local (3)
[46/089ae6] LENGTH_STATS (1) | 3 of 3 ✔
sample2.lengths.txt
sample3.lengths.txt
sample1.lengths.txt
```

Open a task's `.command.sh` (use `find work -name sample1.lengths.txt` to find the folder) and compare it with `blocks.nf`:

```text title="work/ff/bb8c14…/.command.sh (real)"
#!/bin/bash -ue
sleep 3    # pretend this is a slow tool
awk -v min=50 '
    NR % 4 == 2 { reads++; if (length($0) >= min) long++ }
    END { print "reads:", reads, "long enough:", long }
' sample1.fastq > sample1.lengths.txt
echo "bash version: $BASH_VERSION" >> sample1.lengths.txt
```

```text title="sample1.lengths.txt (real)"
reads: 1000 long enough: 1000
bash version: 3.2.57(1)-release
```

Every `${…}` was replaced (`min=50`, `sample1.fastq`), and every `\$` became a plain `$` that Bash and awk then used.

!!! funfact "Fun fact: your tasks run on a bash from 2007"
    `bash version: 3.2.57` is the `/bin/bash` that Apple still ships with macOS. Your SLURM cluster almost certainly has bash 4 or 5. Avoid bash 4-only features in scripts that must run on both, such as associative arrays (`declare -A`) and `${var,,}` for lowercase.

### A stub run: the wiring without the work

```bash title="Terminal"
time nextflow run blocks.nf -stub
```

```text title="Real output"
executor >  local (3)
[6a/f2bd10] LENGTH_STATS (3) | 3 of 3 ✔
sample2.lengths.txt
sample1.lengths.txt
sample3.lengths.txt
```

That took **2 seconds** instead of 5: each task ran the `stub:` block instead of `script:`:

```text title=".command.sh of a stub task (real)"
#!/bin/bash -ue
touch sample1.lengths.txt
```

The output files exist (empty), so every downstream process gets its inputs and the whole pipeline's wiring is tested. With real tools that take hours, a stub run takes seconds.

---

## C. Code walkthrough

### When the two languages get mixed up

`fix_me.nf` (this lesson's challenge) forgets the backslashes. With the strict syntax that Nextflow 26 uses, the mistake is caught **before anything runs**:

```bash title="Terminal"
nextflow run fix_me.nf
```

```text title="Real output"
 N E X T F L O W   ~  version 26.10.7

Launching `fix_me.nf` [adoring_bose] revision: e76be13913

Error fix_me.nf:14:11: Unexpected character: '$'
│  14 |     reads=$(awk 'END { print NR / 4 }' ${fq})
╰     |           ^


ERROR ~ Script compilation failed
```

The two messages you'll meet most:

| Message | Cause | Fix |
|---|---|---|
| ``Unexpected character: '$'`` | A `$` followed by something that isn't a valid name, such as `$(`, `$0`, `$2` | `\$(`, `\$0`, `\$2` |
| `` `i` is not defined `` | A Bash variable like `$i` that Nextflow tried to fill in | `\$i` |

`nextflow lint fix_me.nf` reports the same errors without trying to run anything. It stops at the **first** error, so fix it and run again until it's clean.

!!! gotcha "Gotcha! Single-quoted script blocks"
    You may see script blocks in `'''` triple **single** quotes in older code. Inside them Nextflow fills in **nothing**: every `$` belongs to Bash, but your inputs are unavailable too (`${fq}` reaches Bash literally). Stick to `"""` and backslashes. The old `shell:` section, built around this idea, is **deprecated**: `nextflow lint` warns *"The `shell` block is deprecated, use `script` instead"*.

### `exec:`: a process without Bash

```groovy title="exec.nf"
--8<-- "module04_processes/lesson01_process_blocks/exec.nf"
```

```text title="Real output (the end)"
executor >  local (3)
[43/dfd671] SQUARE (2) | 3 of 3 ✔
1
9
4
```

`exec:` runs Groovy **inside Nextflow itself**: the task folder stays empty (no `.command.sh`), and it can't use containers or a cluster. It's handy for tiny calculations; for anything else, use `script:`. `output: val y` declares a **value** output instead of a file.

!!! protip "Pro tip: stub every process"
    nf-core modules come with a `stub:` section. Typing the `touch` lines takes one minute, and then you can test a change to a 30-process pipeline in seconds: `nextflow run main.nf -stub`.

---

## D. Guided exercise (about 25 min)

```quiz
id: 4.1-ex-steps
type: steps
concept: process-blocks
label: "Mission steps"
steps:
  - "Make the data (`bash ../make_data.sh`) and run `blocks.nf`."
  - "Compare `blocks.nf` with a task's `.command.sh`. Find each `${…}` and each `\\$`."
  - "Run `blocks.nf -stub` with `time`, and look at a stub task's `.command.sh`."
  - "Run `exec.nf`, then `ls -a` one of its task folders."
  - "Run `nextflow lint fix_me.nf` and read the error."
```

```quiz
id: 4.1-ex-a
type: single
concept: interpolation
question: "In `blocks.nf` the awk command contains `length(\\$0)`. What does Bash/awk receive?"
options:
  - text: "`length(\\$0)`"
  - text: "`length($0)`"
    correct: true
  - text: "`length(blocks.nf)`"
explain: "Nextflow removes the backslash and leaves `$0` alone, so awk gets its normal `$0` (the whole input line)."
```

```quiz
id: 4.1-ex-b
type: number
concept: stub
question: "On the test Mac the real run took about 5 s and the stub run about 2 s. If every task really took 3 hours instead of 3 s, roughly how many **hours** would the stub run of 3 parallel tasks take?"
answer: 0
tolerance: 0.1
unit: hours
explain: "Essentially zero: a stub only runs `touch`. The ~2 s are Nextflow's own start-up. That's the whole point of `-stub`: the time of the real tools disappears."
```

```quiz
id: 4.1-ex-c
type: multi
concept: interpolation
question: "Inside a `\"\"\"` script block, which of these need a backslash? Tick all that apply."
options:
  - text: "`$HOME`"
    correct: true
  - text: "`${fq}`, the process input"
  - text: "awk's `$2`"
    correct: true
  - text: "`$(date)`"
    correct: true
explain: "Everything that Bash or awk should handle gets a backslash. `${fq}` is a Nextflow variable, so it must stay as it is."
```

---

## E. Independent challenge

`fix_me.nf` should write a small report per sample: its name, its read count and its number of G+C bases. Make it work:

1. Fix every `$` that belongs to Bash, so the script compiles and runs.
2. Add a **`stub:`** section that only creates the (empty) report file.

```groovy title="fix_me.nf (starter)"
--8<-- "module04_processes/lesson01_process_blocks/fix_me.nf"
```

The checker runs your script on fresh data, compares every report with its own calculation, then runs it **with `-stub`** and checks that the reports are empty.

```quiz
id: 4.1-challenge
type: check
concept: interpolation
label: "Challenge: auto-checked"
check: 4.1-challenge
command: "bash check_fix_me.sh"
solution: includes/solutions/4.1/fix_me.nf
hint: "There are 4 Bash `$` signs to escape: two `$(` and two variables. The `${fq}` and `${fq.baseName}` stay as they are. The `stub:` section goes after `script:`, inside the process, and uses `touch` with the same file name as the output."
explain: "Escaping correctly and stubbing every process are two habits that save hours every week."
```

---

## F. Knowledge check

```quiz
id: 4.1-q1
type: open
concept: interpolation
question: "Explain in your own words why `echo \"$USER\"` fails in a script block but `echo \"\\$USER\"` works."
model: "The script block is read by Nextflow first, and Nextflow treats `$USER` as a reference to a Nextflow variable called USER, which doesn't exist, so compilation fails. With `\\$USER`, Nextflow knows the `$` isn't its own: it removes the backslash and passes `$USER` to Bash, which fills it in when the task runs."
explain: "Two passes: Nextflow first (`${…}`), then Bash (`$…`)."
```

```quiz
id: 4.1-q2
type: single
concept: stub
question: "What does `nextflow run main.nf -stub` test?"
options:
  - text: "That every tool produces correct results."
  - text: "That the pipeline's wiring works: every process runs, in the right order, with the right files, using the `stub:` commands."
    correct: true
  - text: "That the containers can be downloaded."
explain: "Stubs replace the real work with `touch`, so they test channels, inputs, outputs and naming, not the science."
```

```quiz
id: 4.1-q3
type: single
concept: process-blocks
question: "A process has `input: path reads` then `val min_len`. How do you call it?"
options:
  - text: "`FILTER(min_len_ch, reads_ch)`"
  - text: "`FILTER(reads_ch, 50)`"
    correct: true
  - text: "`FILTER(reads: reads_ch, min_len: 50)`"
explain: "Arguments are positional, in the order of the `input:` lines. A plain value such as `50` is accepted where a `val` input is expected."
```

---

## G. Summary

| Concept | Remember |
|---|---|
| Sections | Directives, then `input:`, `output:`, `script:` (or `exec:`), optional `stub:` |
| `${…}` | Filled in by Nextflow before the task runs |
| `\$…` | Left for Bash/awk; the backslash disappears in `.command.sh` |
| `\\t`, `\\n` | Become `\t`, `\n` for awk/printf |
| Strict syntax | Wrong `$` = compile error before anything runs; `nextflow lint` finds it |
| `stub:` + `-stub` | Test the pipeline's wiring in seconds |
| `exec:` | Groovy inside Nextflow; no Bash, no containers |
| `shell:` | Deprecated: use `script:` |

Next: **Lesson 4.2** adds the lines above `input:`, the **directives**: CPUs, memory, time limits, tags, and automatic retries.

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="4.1"></div>
