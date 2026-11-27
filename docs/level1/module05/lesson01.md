---
lesson: "5.1"
module: 5
level: 1
---

# Lesson 5.1: Queue channels and value channels

!!! info "About this lesson"
    **You'll learn:**

    - the two kinds of channel, and how a process **consumes** them;
    - why a process with two inputs runs **as many tasks as its shortest queue**;
    - the classic "only one sample got processed" bug, and three ways to fix it.

    **Why it matters:** this bug doesn't crash anything. The pipeline finishes with a ✔, and you only notice later that 199 of your 200 samples were never processed. Understanding channel types makes it impossible to miss.

    **Time:** about 1.25 h · **Level:** Beginner · **Needs:** Module 4

    **Docs:** [Dataflow and channels](https://docs.seqera.io/nextflow/workflow#dataflow) · [Channels and values](https://docs.seqera.io/nextflow/workflow#channels-and-values) · [`first`](https://docs.seqera.io/nextflow/reference/operator#first)

!!! flo "Flo says"
    From this module on you work with **real** sequencing reads: small public test files from nf-core, the same ones nf-core's own tests use. Welcome to real data!

---

## A. Concept

### Two kinds of channel

| | **Queue channel** | **Value channel** |
|---|---|---|
| Holds | A sequence of items, delivered one by one | Exactly **one** value |
| When a process reads it | Each item is **consumed**: it goes to one task only | The value is **reused** by every task |
| Made by | `channel.of(…)`, `channel.fromPath(…)`, `channel.fromFilePairs(…)`, process outputs… | `channel.value(…)`, `.first()`, `.collect()`, a plain value or `file(…)` passed to a process |
| Python analogy | An **iterator**: each `next()` gives a new item, once | A **constant** |

### How a process with two inputs decides how many tasks to run

Every task needs **one item from each input**. Nextflow pairs the inputs up in order: the first item of each, then the second of each, and so on, and stops when **any** queue channel runs out.

=== "Nextflow"

    ```groovy title="pairing.nf"
    --8<-- "module05_channels/lesson01_queue_value/pairing.nf"
    ```

=== "Python equivalent"

    ```python title="pairing.py"
    --8<-- "module05_channels/lesson01_queue_value/pairing.py"
    ```

    ```text title="Real output: python3 pairing.py"
    1 + a
    2 + b
    -- the reference in a queue channel: channel.fromPath('ref.fa')
    cov_a_R1 mapped against ref.fa
    -- the reference as a value: channel.value(file('ref.fa'))
    cov_a_R1 mapped against ref.fa
    cov_b_R1 mapped against ref.fa
    hsa_rna_R1 mapped against ref.fa
    ```

!!! note "Where the analogy stops"
    `zip` works on inputs that already exist. Channels deliver items **over time**, and a task starts as soon as one item from each input is there, so which sample gets the single reference is random in Nextflow (see section B). The rule is the same in both: items are paired in order, and the shortest input decides.

```text title="Real output (the end)"
executor >  local (2)
[65/6ffed8] PAIR (2) | 2 of 2 ✔
1 + a
2 + b
```

Two tasks: `3` never found a partner. **No error, no warning.**

### The classic bug

A reference genome is one file, but `channel.fromPath('ref.fa')` makes a **queue** channel with one item. The first sample uses it up:

--8<-- "includes/anim/queue_value.html"

!!! analogy "Real-life analogy: a single pipette tip vs a tip box"
    A queue channel is a stack of single-use tips: each sample takes one, and when the stack is empty, the next sample waits forever. A value channel is the bench protocol pinned to the wall: everyone reads the same sheet, and it's never used up.

---

## B. Demonstration

Download the real data into the lesson folder (about 400 KB, checked with SHA-256):

```bash title="Terminal"
cd "$COURSE"/module05_channels/lesson01_queue_value
bash ../get_data.sh
```

```text title="Real output"
downloaded         data/cov_a_R1.fastq.gz
downloaded         data/cov_a_R2.fastq.gz
downloaded         data/cov_b_R1.fastq.gz
downloaded         data/cov_b_R2.fastq.gz
downloaded         data/hsa_rna_R1.fastq.gz
downloaded         data/hsa_rna_R2.fastq.gz
```

| Sample | What it is | Read pairs |
|---|---|---|
| `cov_a`, `cov_b` | SARS-CoV-2 Illumina reads, 150 bp | 100 each |
| `hsa_rna` | Human RNA-seq reads | 4,159 |

Now run the buggy pipeline:

```groovy title="map_reads.nf"
--8<-- "module05_channels/lesson01_queue_value/map_reads.nf"
```

```bash title="Terminal"
nextflow run map_reads.nf
```

??? predict "Predict: three samples. How many MAP_READS tasks?"
    Real output:

    ```text title="Real output"
    executor >  local (1)
    [d7/cf108e] MAP_READS (cov_b_R1) | 1 of 1 ✔
    cov_b_R1 mapped against ref.fa
    ```

    **One.** A ✔ and no error, but two samples were silently skipped. Which one runs is random: whichever read file arrived first.

---

## C. Code walkthrough: three fixes

Any of these makes all three samples run:

```groovy
// 1. Take the first (and only) item of the queue as a value channel
ref_ch = channel.fromPath('ref.fa').first()

// 2. Make a value channel directly
ref_ch = channel.value(file('ref.fa'))

// 3. Skip the channel: pass the file itself (Nextflow treats it as a value)
MAP_READS(reads_ch, file('ref.fa'))
```

With the second fix, the real output was:

```text title="Real output"
executor >  local (3)
[d5/496b3b] MAP_READS (hsa_rna_R1) | 3 of 3 ✔
cov_b_R1 mapped against ref.fa
cov_a_R1 mapped against ref.fa
hsa_rna_R1 mapped against ref.fa
```

The same applies to any "one thing for every sample" input: a reference, an index, an adapter sequence, a GTF file, a parameter value read into a channel.

!!! gotcha "Gotcha! `collect()` returns a value channel"
    In Lesson 3.2, `SUMMARISE(counts_ch.collect())` ran once, with everything. That worked because `collect()` emits **one** value, as a value channel. That's also why you can give the same collected list to two different processes.

!!! protip "Pro tip: check the task counts"
    After every run, glance at the counts: `MAP_READS | 3 of 3`. If a per-sample step shows **1 of 1** when you have 3 samples, look for a single-item queue channel.

---

## D. Guided exercise (about 25 min)

```quiz
id: 5.1-ex-steps
type: steps
concept: channel-types
label: "Mission steps"
steps:
  - "Download the data with `bash ../get_data.sh`."
  - "Run `pairing.nf`. Why two tasks?"
  - "Run `map_reads.nf` and count the tasks."
  - "Apply each of the three fixes from section C, one at a time, and run again."
  - "Run `fix_ref.nf` (the challenge) once as it is, and count its `TRIM_AND_MAP` tasks."
```

```quiz
id: 5.1-ex-a
type: number
concept: channel-types
question: "A process has two queue-channel inputs: one with 10 FASTQ files, one with 4 adapter sequences. How many tasks run?"
answer: 4
tolerance: 0
unit: tasks
explain: "Items are paired in order and the shortest queue decides: 4 pairs, 4 tasks. The other 6 FASTQ files are silently left over."
```

```quiz
id: 5.1-ex-b
type: multi
concept: channel-types
question: "Which of these are **value** channels (reused by every task)? Tick all that apply."
options:
  - text: "`channel.value(file('ref.fa'))`"
    correct: true
  - text: "`channel.fromPath('ref.fa')`"
  - text: "`channel.fromPath('ref.fa').first()`"
    correct: true
  - text: "`counts_ch.collect()`"
    correct: true
  - text: "`channel.of('AGATCGGAAGAGC')`"
explain: "`fromPath` and `of` make queue channels, even with one item. `value`, `first` and `collect` produce a single, reusable value."
```

---

## E. Independent challenge

`fix_ref.nf` trims and maps every sample (pretend), then writes a summary. It has three samples but processes **one**. Make every sample run, without changing the processes. There's more than one single-item queue channel in there.

```groovy title="fix_ref.nf (starter)"
--8<-- "module05_channels/lesson01_queue_value/fix_ref.nf"
```

The checker runs your pipeline on **4** fresh samples with `--reference genome.fa --adapter CTGTCTCTTATA`, and expects 4 tasks and a summary line for each sample.

```quiz
id: 5.1-challenge
type: check
concept: channel-types
label: "Challenge: auto-checked"
check: 5.1-challenge
command: "bash check_fix_ref.sh"
solution: includes/solutions/5.1/fix_ref.nf
hint: "Two of the three inputs of TRIM_AND_MAP are \"one thing for every sample\". Both need to be value channels. Section C lists three ways to do it."
explain: "In real pipelines, references, indexes and settings are value inputs; only the per-sample data travels in queue channels."
```

---

## F. Knowledge check

```quiz
id: 5.1-q1
type: open
concept: channel-types
question: "Explain why `MAP_READS(reads_ch, channel.fromPath('ref.fa'))` with 3 samples runs only one task, and why Nextflow doesn't report an error."
model: "`channel.fromPath('ref.fa')` makes a queue channel with a single item. Each task takes one item from each input; the first task takes ref.fa, so the reference queue is empty and the remaining samples can't be paired: no more tasks are created. This isn't an error: the channels simply ran out of matching items, which is a normal way for a run to end. Fix it with a value channel (channel.value, .first(), or passing file('ref.fa') directly)."
explain: "Shortest queue wins, and \"running out\" is normal behaviour."
```

```quiz
id: 5.1-q2
type: single
concept: channel-types
question: "Can one queue channel be given to two different processes?"
options:
  - text: "No: the first process consumes every item."
  - text: "Yes: each process gets its own copy of every item."
    correct: true
explain: "You did exactly this in Lesson 3.2's challenge (`COUNT_READS` and `GC_CONTENT` both read `reads_ch`). \"Consuming\" happens per process input, not per channel."
```

---

## G. Summary

| Concept | Remember |
|---|---|
| Queue channel | Items delivered one by one, each to one task |
| Value channel | One value, reused by every task |
| Several inputs | Paired in order; the shortest queue decides the number of tasks |
| Classic bug | One reference in a queue channel → 1 task, no error |
| Fixes | `channel.value(file(…))`, `.first()`, or pass `file(…)` directly |
| `collect()` | Produces a value channel |

Next: **Lesson 5.2** covers every common way of **creating** channels, including the one real pipelines use most: a samplesheet.

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="5.1"></div>
