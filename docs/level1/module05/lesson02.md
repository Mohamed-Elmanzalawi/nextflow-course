---
lesson: "5.2"
module: 5
level: 1
---

# Lesson 5.2: Channel factories and samplesheets

!!! info "About this lesson"
    **You'll learn:**

    - the channel factories you'll use most: `channel.of`, `fromList`, `fromPath`, `fromFilePairs`;
    - how to read a **samplesheet** with `splitCsv` and turn each row into a tuple;
    - how `checkIfExists` turns silent mistakes into clear errors.

    **Why it matters:** every nf-core pipeline starts from a samplesheet: `--input samplesheet.csv`. A samplesheet says exactly which files belong to which sample, whatever the files are called. Glob patterns can't do that.

    **Time:** about 1.5 h · **Level:** Beginner · **Needs:** Lesson 5.1

    **Docs:** [Channel factories](https://docs.seqera.io/nextflow/reference/channel) · [`splitCsv`](https://docs.seqera.io/nextflow/reference/operator#splitcsv) · [Working with files](https://docs.seqera.io/nextflow/working-with-files)

!!! flo "Flo says"
    So far your file names were tidy: `sample1.fastq`, `cov_a_R1.fastq.gz`. Real sequencing runs give you `Lib23_S7_L003_R1_001.fastq.gz`. Today you learn the tool that copes with anything: the samplesheet.

---

## A. Concept

### The factories

| Factory | Emits | Example |
|---|---|---|
| `channel.of(a, b, c)` | Each argument | `channel.of('cov_a', 'cov_b')` |
| `channel.fromList(list)` | Each element of a list | `channel.fromList(['x', 'y'])` |
| `channel.fromPath('glob')` | One file per match | `channel.fromPath('data/*_R1.fastq.gz')` |
| `channel.fromFilePairs('glob')` | `[id, [file1, file2]]` per pair | `channel.fromFilePairs('data/*_R{1,2}.fastq.gz')` |
| `channel.fromPath(sheet).splitCsv(header: true)` | One **map** per CSV line | `[sample:cov_a, fastq_1:…, fastq_2:…]` |

In `fromFilePairs`, `{1,2}` marks the part that differs between the two files of a pair, and the part matched by `*` becomes the **id**: `cov_a_R{1,2}.fastq.gz` → `cov_a`.

### A samplesheet

```text title="samplesheet.csv"
--8<-- "module05_channels/lesson02_factories/samplesheet.csv"
```

Three steps turn it into a channel of samples:

--8<-- "includes/anim/samplesheet.html"

```groovy title="the pattern"
samples = channel.fromPath(params.input)
    .splitCsv(header: true)
    .map { row ->
        tuple(row.sample, file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true))
    }
```

- `splitCsv(header: true)` turns each line into a **map** (a Python **dict**): `row.sample` is like `row["sample"]`.
- `.map { row -> … }` is an **operator**: it applies the closure to every item (Python: `map(lambda row: …, rows)`).
- `file(path)` turns a text path into a file object, so a process can stage it. With `checkIfExists: true`, a wrong path stops the run immediately.

!!! analogy "Real-life analogy: a sample manifest"
    A glob is like grabbing every tube on the rack whose label starts with "S". A samplesheet is the lab's sample manifest: one line per sample, saying exactly which tubes belong to it, whatever is written on them.

---

## B. Demonstration

```bash title="Terminal"
cd "$COURSE"/module05_channels/lesson02_factories
bash ../get_data.sh
nextflow run factories.nf
```

```groovy title="factories.nf"
--8<-- "module05_channels/lesson02_factories/factories.nf"
```

```text title="Real output"
of:        cov_a
fromList:  x
of:        cov_b
fromList:  y
fromPath:  cov_b_R1.fastq.gz
fromPath:  cov_a_R1.fastq.gz
fromPath:  hsa_rna_R1.fastq.gz
csv row:   [sample:cov_a, fastq_1:data/cov_a_R1.fastq.gz, fastq_2:data/cov_a_R2.fastq.gz]
csv row:   [sample:cov_b, fastq_1:data/cov_b_R1.fastq.gz, fastq_2:data/cov_b_R2.fastq.gz]
csv row:   [sample:hsa_rna, fastq_1:data/hsa_rna_R1.fastq.gz, fastq_2:data/hsa_rna_R2.fastq.gz]
pairs:     cov_b [cov_b_R1.fastq.gz, cov_b_R2.fastq.gz]
pairs:     hsa_rna [hsa_rna_R1.fastq.gz, hsa_rna_R2.fastq.gz]
pairs:     cov_a [cov_a_R1.fastq.gz, cov_a_R2.fastq.gz]
tuple:     cov_a cov_a_R1.fastq.gz cov_a_R2.fastq.gz
tuple:     cov_b cov_b_R1.fastq.gz cov_b_R2.fastq.gz
tuple:     hsa_rna hsa_rna_R1.fastq.gz hsa_rna_R2.fastq.gz
```

All the channels run **at the same time**, so their lines are interleaved, and files from `fromPath` arrive in no particular order. The `csv row` lines show what `splitCsv` makes: one map per line, with the header names as keys.

---

## C. Code walkthrough

### When something doesn't exist

Two silent traps, and how `checkIfExists` closes them.

**A glob that matches nothing** gives an **empty channel**. In a real test, `channel.fromPath('data/*_R3.fastq.gz').view()` printed **nothing at all** and the run ended normally. With `checkIfExists: true`:

```text title="Real output"
ERROR ~ No files match pattern `*_R3.fastq.gz` at path: data/
```

**A samplesheet row pointing to a missing file.** With `file(row.fastq_2, checkIfExists: true)` and a typo in the sheet (`cov_b_R3.fastq.gz`):

```text title="Real output: nextflow run factories.nf --input typo.csv (path shortened)"
tuple:     cov_a cov_a_R1.fastq.gz cov_a_R2.fastq.gz
ERROR ~ No such file or directory: …/data/cov_b_R3.fastq.gz

 -- Check script 'factories.nf' at line: 17 or see '.nextflow.log' file for more details
```

The run stops at once, and the message names the file. Without `checkIfExists`, the missing file would only be noticed later, inside a task, after the other samples have already used up compute time.

!!! gotcha "Gotcha! Paths in a samplesheet are relative to where you launch"
    `data/cov_a_R1.fastq.gz` in the sheet is looked up from the folder where you run `nextflow`, not from the folder of the samplesheet. On a cluster, absolute paths (`/scratch/me/run7/…`) are the safest.

!!! protip "Pro tip: validate samplesheets properly"
    nf-core pipelines check every samplesheet column (types, allowed values, file existence) with the **nf-schema** plugin. You'll use it in Module 11. Until then, `checkIfExists` is your safety net.

---

## D. Guided exercise (about 30 min)

```quiz
id: 5.2-ex-steps
type: steps
concept: channel-factories
label: "Mission steps"
steps:
  - "Run `factories.nf` and match every output line to its factory."
  - "Change the `fromFilePairs` pattern to `'data/*_R{1,2}.fq.gz'` (wrong extension). What do the `pairs:` lines show now?"
  - "Make a copy of `samplesheet.csv` with one wrong file name and run `nextflow run factories.nf --input your_copy.csv`."
  - "Read the TODO in `read_sheet.nf` (the challenge)."
```

```quiz
id: 5.2-ex-a
type: single
concept: channel-factories
question: "With the pattern `'data/*_R{1,2}.fq.gz'`, the `pairs:` lines…"
options:
  - text: "show an error."
  - text: "disappear: the pattern matches nothing, so the channel is empty."
    correct: true
  - text: "show the same pairs as before."
explain: "No match means an empty channel, silently. `fromFilePairs` also accepts `checkIfExists: true`; in a test it then stopped with: No files match pattern `*_R{1,2}.fq.gz` at path: data/"
```

```quiz
id: 5.2-ex-b
type: single
concept: samplesheets
question: "After `splitCsv(header: true)`, how do you get the R1 path of a row?"
options:
  - text: "`row[1]`"
  - text: "`row.fastq_1`"
    correct: true
  - text: "`row.R1`"
explain: "With `header: true`, each row is a map whose keys are the header's column names. Without `header: true`, rows are lists and you'd use positions."
```

```quiz
id: 5.2-ex-c
type: single
concept: channel-factories
question: "Your files are called `Lib23_S7_L003_R1_001.fastq.gz` and `Lib23_S7_L003_R2_001.fastq.gz`, and each library was sequenced on 4 lanes. What's the most reliable way to tell the pipeline which files belong together?"
options:
  - text: "A clever `fromFilePairs` glob."
  - text: "A samplesheet listing each sample's files explicitly."
    correct: true
  - text: "Rename all the files by hand first."
explain: "A samplesheet doesn't care about naming conventions, is easy to review, and documents exactly what went into the analysis."
```

---

## E. Independent challenge

`read_sheet.nf` has a finished `COUNT_PAIRS` process (it counts the reads in R1 and R2) and a `REPORT`. Write the missing channel: read `params.input`, turn each row into `tuple(sample, R1 file, R2 file)`, and make **every** file checked, so a missing file stops the run with an error that names it.

```groovy title="read_sheet.nf (starter)"
--8<-- "module05_channels/lesson02_factories/read_sheet.nf"
```

The checker runs your pipeline on a new samplesheet whose files are called `run_07/lane1_forward.fq.gz` and similar (no `R1`/`R2` anywhere), then on a samplesheet with a missing file.

```quiz
id: 5.2-challenge
type: check
concept: samplesheets
label: "Challenge: auto-checked"
check: 5.2-challenge
command: "bash check_read_sheet.sh"
solution: includes/solutions/5.2/read_sheet.nf
hint: "Section A has the whole pattern. Replace `channel.empty()` with it, and check that the tuple matches COUNT_PAIRS's input: `tuple val(sample), path(r1), path(r2)`."
explain: "You've just written the first lines of every nf-core pipeline. In Lesson 5.4 the plain sample name becomes a meta map."
```

---

## F. Knowledge check

```quiz
id: 5.2-q1
type: open
concept: samplesheets
question: "Give two reasons why nf-core pipelines use a samplesheet instead of a glob pattern for their input."
model: "1) A samplesheet states explicitly which files belong to which sample, regardless of file naming, and it can list several lanes or runs per sample. 2) It can carry extra information per sample (condition, strandedness, single- or paired-end) that a file name can't. Also: it's a reviewable record of exactly what was analysed, and files can live in different folders."
explain: "Explicit beats clever."
```

```quiz
id: 5.2-q2
type: single
concept: checkifexists
question: "What does `checkIfExists: true` change?"
options:
  - text: "It makes Nextflow create missing files."
  - text: "A missing file (or a pattern with no matches) stops the run immediately, with an error naming it, instead of giving an empty channel or failing later inside a task."
    correct: true
  - text: "Nothing, it's the default."
explain: "It's not the default: an unmatched pattern silently gives an empty channel. Use it on every input."
```

---

## G. Summary

| Factory / operator | Gives |
|---|---|
| `channel.of(…)` / `fromList(…)` | One item per value |
| `channel.fromPath('glob')` | One file per match (empty if none!) |
| `channel.fromFilePairs('x_R{1,2}.fq.gz')` | `[id, [R1, R2]]` |
| `.splitCsv(header: true)` | One map per CSV line: `row.column` |
| `.map { row -> … }` | Transform every item (Python `map`) |
| `file(path, checkIfExists: true)` | A file object; stops the run if it's missing |

Next: **Lesson 5.3**: the operators that reshape channels: `filter`, `join`, `groupTuple`, `combine` and friends.

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="5.2"></div>
