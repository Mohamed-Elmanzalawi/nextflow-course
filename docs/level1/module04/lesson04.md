---
lesson: "4.4"
module: 4
level: 1
---

# Lesson 4.4: Inputs and outputs in depth

!!! info "About this lesson"
    **You'll learn:**

    - the real difference between `val` and `path` inputs;
    - how **glob** outputs capture a varying number of files, and when you get a list;
    - how `emit:` gives outputs **names**;
    - how `optional: true` handles files that only some tasks produce;
    - how `flatten()` turns a list of files into one item per file.

    **Why it matters:** real tools rarely produce exactly one file. FastQC writes an HTML and a zip; a splitter writes "as many chunks as needed"; a variant caller might write a VCF only if it finds variants. Your process must describe all of that precisely.

    **Time:** about 1.25 h · **Level:** Beginner · **Needs:** Lesson 4.3

    **Docs:** [Inputs](https://docs.seqera.io/nextflow/process#inputs) · [Outputs](https://docs.seqera.io/nextflow/process#outputs) · [`flatten`](https://docs.seqera.io/nextflow/reference/operator#flatten)

!!! flo "Flo says"
    This is the last lesson about the inside of a process. Next module, you'll zoom out to the channels that connect them, and everything here is what flows through them.

---

## A. Concept

### `val` or `path`?

Both can receive a file, but only one **stages** it:

```groovy title="val_vs_path.nf"
--8<-- "module04_processes/lesson04_inputs_outputs/val_vs_path.nf"
```

| | `val fq` | `path fq` |
|---|---|---|
| In the task folder | Nothing: the task gets the **full original path** as text | A **link** to the file, under its own name |
| Works on your laptop | Usually | Yes |
| Works in containers and on a cluster | Often **not**: the original path may not exist there | Yes: Nextflow makes the file available |
| Part of the task hash (`-resume`) | The text of the path | The file's path, size and timestamp |

**Rule:** anything that's a file is a `path` input. `val` is for numbers, names and settings.

### Outputs: globs, names and optional files

```groovy title="split.nf (the process)"
    output:
    path 'chunk_*.fastq', emit: chunks                // (1)!
    path 'n_chunks.txt', emit: n                      // (2)!
    path 'warning.txt', optional: true, emit: warning // (3)!
```

1. A **glob**: every file in the task folder matching `chunk_*.fastq` is captured. Several matching files arrive as **one item: a list of files**.
2. `emit:` names the output. After `out = SPLIT(…)` you write `out.chunks`, `out.n`, `out.warning` (or `SPLIT.out.chunks` and so on).
3. Only some tasks create `warning.txt`. Without `optional: true`, those that don't would fail with *Missing output file(s)*.

--8<-- "includes/anim/emit_outputs.html"

!!! gotcha "Gotcha! One file or a list?"
    A glob that matches **several** files gives a list. One that matches **exactly one** file gives a single file, not a list of one. In a test, the same output gave a list for 4 chunks but a single `UnixPath` (a file) for 1 chunk. Code that expects a list then breaks for small samples. Fix it with **`arity: '1..*'`**: "one or more files, always as a list". With it, the 1-chunk case gave `ArrayList: [chunk_01.fastq]`.

---

## B. Demonstration

```bash title="Terminal"
cd ~/Desktop/Projects/learning_nextflow/module04_processes/lesson04_inputs_outputs
bash ../make_data.sh
nextflow run split.nf
```

```text title="Real output"
executor >  local (3)
[c9/9c86f4] SPLIT (2) | 3 of 3 ✔
chunks:  [chunk_sample2_01.fastq, chunk_sample2_02.fastq, chunk_sample2_03.fastq, chunk_sample2_04.fastq]
chunks:  [chunk_sample3_01.fastq, chunk_sample3_02.fastq, chunk_sample3_03.fastq, chunk_sample3_04.fastq]
chunks:  [chunk_sample1_01.fastq, chunk_sample1_02.fastq, chunk_sample1_03.fastq]
```

400 reads per chunk: sample1 (1000 reads) makes 3 chunks, sample2 (1250) and sample3 (1500) make 4. Each task emitted **one list**. No sample made more than 4 chunks, so nothing went down `warning`: no `warning:` line was printed.

```bash title="Terminal"
nextflow run val_vs_path.nf
```

```text title="Real output (paths shortened)"
executor >  local (2)
[09/2589fd] AS_VAL (1)  | 1 of 1 ✔
[a4/779e4d] AS_PATH (1) | 1 of 1 ✔
val : -rw-r--r-- …/lesson04_inputs_outputs/data/sample1.fastq
path: lrwxr-xr-x sample1.fastq -> …/lesson04_inputs_outputs/data/sample1.fastq
```

`AS_VAL` read the **original** file through its full path. `AS_PATH` got a **link** in its own folder.

---

## C. Code walkthrough

### From lists to single files: `flatten()`

In the challenge, each chunk must be counted by its own task. But `out.chunks` delivers **one list per sample**. Given straight to a process, each list would be **one** task with several files. `flatten()` is an operator (Module 5) that unpacks lists:

```groovy
COUNT_CHUNK(out.chunks.flatten())   // [c1, c2, c3], [c1] → c1, c2, c3, c1 → 4 tasks
```

### What the full pipeline does

The reference solution of this lesson's challenge, run with 1100 reads per chunk on the three samples:

```text title="Real output"
executor >  local (9)
[2e/e23a5d] SPLIT (2)       | 3 of 3 ✔
[6e/dc6f32] COUNT_CHUNK (5) | 5 of 5 ✔
[03/4464a2] TOTAL           | 1 of 1 ✔
small sample: sample1.small
```

```text title="chunk_counts.tsv (real)"
chunk_sample1_01	1000
chunk_sample2_01	1100
chunk_sample2_02	150
chunk_sample3_01	1100
chunk_sample3_02	400
```

3 + 5 + 1 = 9 tasks. Only `sample1` (1000 reads, fewer than 1100) produced the optional `.small` file.

### Other output forms you'll meet

| Output | Meaning |
|---|---|
| `val x` | A value instead of a file, for example the result of an `exec:` block (Lesson 4.1) |
| `stdout` | Whatever the task printed: used with `.view()` in this lesson |
| `env 'NAME'` | The value of a Bash variable at the end of the script |
| `tuple val(id), path('*.bam')` | Several things travelling **together**. That's Module 5's main topic. |

!!! gotcha "Gotcha! A glob that matches nothing"
    If no file matches a (non-optional) glob, the task fails. In a test with a misspelled pattern: `Missing output file(s) `part_*.fastq` expected by process `SPLIT (1)``. When this happens, `ls` the task folder and compare the real file names with your pattern.

!!! protip "Pro tip: name every output"
    `emit:` names make workflows readable: `FASTQC.out.zip` says more than `FASTQC.out[1]`. nf-core names every output of every module.

---

## D. Guided exercise (about 25 min)

```quiz
id: 4.4-ex-steps
type: steps
concept: outputs
label: "Mission steps"
steps:
  - "Run `split.nf` and count the chunks per sample."
  - "Change 400 to 100 in the workflow of `split.nf` and run again. Which samples now send something down `warning`?"
  - "Run `val_vs_path.nf` and compare the two lines."
  - "Read the TODOs in `chunks.nf` (the challenge)."
```

```quiz
id: 4.4-ex-a
type: number
concept: outputs
question: "With 100 reads per chunk, how many chunk files does `sample2` (1250 reads) produce?"
answer: 13
tolerance: 0
unit: chunks
explain: "1250 / 100 = 12.5, so 12 full chunks plus one with the last 50 reads = 13. That's more than 4, so sample2 also writes `warning.txt`."
```

```quiz
id: 4.4-ex-b
type: single
concept: inputs
question: "Your process reads a reference genome. Which input type?"
options:
  - text: "`val reference`, because it's the same for every task."
  - text: "`path reference`, because it's a file: it must be staged so the task can read it in a container or on a cluster node."
    correct: true
explain: "\"Same for every task\" is about channels (Module 5: value channels), not about `val` vs `path`. A file is always a `path`."
```

```quiz
id: 4.4-ex-c
type: single
concept: outputs
question: "A process declares `path '*.vcf', optional: true, emit: vcf`. A task finds no variants and writes no VCF. What happens?"
options:
  - text: "The task fails with Missing output file(s)."
  - text: "The task succeeds; it simply sends nothing down `vcf`."
    correct: true
  - text: "Nextflow creates an empty VCF."
explain: "That's exactly what `optional: true` is for. Downstream processes just receive one item fewer."
```

---

## E. Independent challenge

Complete `chunks.nf`. It splits each sample into chunks of `--reads_per_chunk` reads, counts every chunk in its own task, and collects all counts in `chunk_counts.tsv`:

1. In `SPLIT`'s `output:`, name the chunk files **`chunks`**, and make them **always a list**, even when there's only one chunk.
2. Add the `<sample>.small` file that small samples create, as an **optional** output named **`small`**.
3. In the workflow, run `COUNT_CHUNK` **once per chunk file**.
4. Give all the counts to `TOTAL` at once, and `view()` its output. Also `view()` the small-sample files.

```groovy title="chunks.nf (starter)"
--8<-- "module04_processes/lesson04_inputs_outputs/chunks.nf"
```

The checker runs your pipeline with `--reads_per_chunk 300` on 4 fresh samples (200, 450, 700 and 950 reads), so it expects 1 + 2 + 3 + 4 = 10 chunk counts, and exactly one `.small` file.

```quiz
id: 4.4-challenge
type: check
concept: outputs
label: "Challenge: auto-checked"
check: 4.4-challenge
command: "bash check_chunks.sh"
solution: includes/solutions/4.4/chunks.nf
hint: "Outputs: `path 'chunk_*.fastq', arity: '1..*', emit: chunks` is the pattern for TODO 1; TODO 2 combines `optional: true` and `emit:`. Workflow: `split_out.chunks.flatten()` for TODO 3, `.collect()` for TODO 4 (Lesson 3.2)."
explain: "Lists from globs, `flatten()` to fan out, `collect()` to gather back: this split → process → merge shape is how big FASTQ or BAM files are processed in parallel."
```

---

## F. Knowledge check

```quiz
id: 4.4-q1
type: open
concept: inputs
question: "A colleague's pipeline uses `val bam` for BAM file inputs. It works on their laptop but fails on the cluster with Docker. Explain why, and the fix."
model: "With `val`, the task receives the BAM's original path as plain text and nothing is staged into the task folder. Inside a container (or on another node) that path may not exist or not be mounted, so the tool can't open the file. Declaring `path bam` makes Nextflow stage the file into the task folder, which is available inside the container: the tool reads it by its name."
explain: "Files are `path`. Always."
```

```quiz
id: 4.4-q2
type: single
concept: outputs
question: "What does `arity: '1..*'` on a glob output guarantee?"
options:
  - text: "At most one file."
  - text: "At least one file, always delivered as a list, even when only one file matches."
    correct: true
  - text: "That the files are sorted."
explain: "It removes the \"one file vs list\" surprise, and it fails the task if nothing matches."
```

```quiz
id: 4.4-q3
type: single
concept: flatten
question: "`SPLIT.out.chunks` delivers `[a, b]` and `[c]`. How many items does `SPLIT.out.chunks.flatten()` deliver?"
options:
  - text: "2"
  - text: "3"
    correct: true
  - text: "1"
explain: "`flatten()` unpacks every list: a, b, c. Without it, a process would see 2 items (2 tasks), each with a list of files."
```

---

## G. Summary

| Concept | Remember |
|---|---|
| `val` vs `path` | Files are `path` (staged as links); `val` is for values |
| Glob output | `path 'chunk_*.fastq'`: several matches → one list |
| `arity: '1..*'` | Always a list, at least one file |
| `emit: name` | Named outputs: `PROC.out.name` |
| `optional: true` | The file may be missing; nothing is sent then |
| `flatten()` | Unpacks lists: one item per file |
| Missing output | Compare `ls` in the task folder with the declared pattern |

!!! flo "Module 4 complete!"
    You now know a process inside out: its sections, its directives, how it fails and how to debug it, and every shape of input and output. **Module 5** zooms out to the channels between processes: queue vs value channels, samplesheets, operators, and the meta-map pattern used by every nf-core pipeline.

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="4.4"></div>
