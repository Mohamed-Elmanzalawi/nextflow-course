---
lesson: "5.4"
module: 5
level: 1
---

# Lesson 5.4: Tuples and meta maps

!!! info "About this lesson"
    **You'll learn:**

    - why pipelines carry **information about a sample** along with its files;
    - the **meta-map pattern**, `[meta, files]`, used by every nf-core module;
    - how processes take and emit `tuple val(meta), path(…)`;
    - how to add a field to a meta map, and why `join` keeps working.

    **Why it matters:** read the code of any nf-core pipeline and you'll see `tuple val(meta), path(reads)` everywhere. Once you know this pattern, nf-core modules become readable, and your own pipelines stop breaking every time you add a column to the samplesheet.

    **Time:** about 1.5 h · **Level:** Beginner · **Needs:** Lessons 5.2 and 5.3

    **Docs:** [Tuples in process inputs](https://docs.seqera.io/nextflow/process#input-tuples-tuple) · [nf-core meta map](https://nf-co.re/docs/contributing/components/meta_map)

!!! flo "Flo says"
    Last lesson of Level 1's theory! After this, the capstone: a real QC pipeline, built by you from the ground up.

---

## A. Concept

### The problem: positions

In Lesson 5.2 a sample was `tuple(sample, r1, r2)`. Add a `condition` column and every process input, every output and every `map` must change, because they all count positions. Add `batch`, and it happens again. (This lesson's challenge starter shows how messy that gets.)

### The solution: one map of facts + the files

```groovy
[ [id: 'cov_a', condition: 'infected', single_end: false],  [cov_a_R1.fastq.gz, cov_a_R2.fastq.gz] ]
//  └──────────────── meta: facts about the sample ─────────┘  └──────────── the files ────────────┘
```

| Part | What | Python analogy |
|---|---|---|
| `meta` | A **map** of facts: `id`, condition, strandedness, … | A dict: `{"id": "cov_a", "condition": "infected"}` |
| files | One file or a list of files | A list of paths |

Processes then always look like this:

```groovy
process COUNT_PAIRS {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.count.txt")
    …
}
```

Adding a column to the samplesheet now means adding **one key** to the meta map. No process needs to change.

--8<-- "includes/anim/meta_map.html"

!!! analogy "Real-life analogy: a luggage tag"
    The suitcase's contents (the files) change at every step: unpacked, washed, repacked. The luggage tag (meta) stays attached the whole way, so everyone always knows whose suitcase it is.

---

## B. Demonstration

=== "Nextflow"

    ```groovy title="meta.nf"
    --8<-- "module05_channels/lesson04_meta_maps/meta.nf"
    ```

=== "Python equivalent"

    ```python title="meta.py"
    --8<-- "module05_channels/lesson04_meta_maps/meta.py"
    ```

    ```text title="Real output: python3 meta.py (after bash ../get_data.sh)"
    in:  [id:cov_a, condition:infected, single_end:false] [cov_a_R1.fastq.gz, cov_a_R2.fastq.gz]
    in:  [id:cov_b, condition:infected, single_end:false] [cov_b_R1.fastq.gz, cov_b_R2.fastq.gz]
    in:  [id:hsa_rna, condition:control, single_end:false] [hsa_rna_R1.fastq.gz, hsa_rna_R2.fastq.gz]
    out: [id:cov_a, condition:infected, single_end:false, read_pairs:100]
    out: [id:cov_b, condition:infected, single_end:false, read_pairs:100]
    out: [id:hsa_rna, condition:control, single_end:false, read_pairs:4159]
    oops: [id:cov_a, condition:infected, single_end:false, read_pairs:0]
    ```

!!! note "Where the analogy stops"
    The `oops` line is the in-place-change bug from section C, made visible: changing the dict "after" `COUNT_PAIRS` also changed the item that went **in**. Python and Nextflow share this behaviour, and the fix is the same: build a new map, `{**meta, "read_pairs": n}` in Python, `meta + [read_pairs: n]` in Nextflow. In Nextflow it matters even more, because the same map travels through several processes running at the same time.

```bash title="Terminal"
cd "$COURSE"/module05_channels/lesson04_meta_maps
bash ../get_data.sh
nextflow run meta.nf
```

```text title="Real output (the end)"
executor >  local (3)
[0d/5c9c74] COUNT_PAIRS (hsa_rna) | 3 of 3 ✔
in:  [id:cov_a, condition:infected, single_end:false] [cov_a_R1.fastq.gz, cov_a_R2.fastq.gz]
in:  [id:cov_b, condition:infected, single_end:false] [cov_b_R1.fastq.gz, cov_b_R2.fastq.gz]
in:  [id:hsa_rna, condition:control, single_end:false] [hsa_rna_R1.fastq.gz, hsa_rna_R2.fastq.gz]
out: [id:cov_b, condition:infected, single_end:false, read_pairs:100]
out: [id:cov_a, condition:infected, single_end:false, read_pairs:100]
out: [id:hsa_rna, condition:control, single_end:false, read_pairs:4159]
```

The `in:` lines show the `[meta, files]` pairs built from the samplesheet. The `out:` lines show the same meta maps after the process, with a new field, `read_pairs`, read from each task's output file.

---

## C. Code walkthrough

### Building the meta map

```groovy
.map { row ->
    def meta = [id: row.sample, condition: row.condition, single_end: false]
    tuple(meta, [file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true)])
}
```

- `[key: value, …]` is a map literal (Python: `{"key": value}`). `def` declares a local variable inside the closure.
- `id` is the one key every nf-core module expects: it's used for tags and file names.
- `single_end` tells modules whether `reads` holds one file or two.

### Using it in a process

| Write | Gets |
|---|---|
| `tag "${meta.id}"` | Readable task names: `COUNT_PAIRS (hsa_rna)` |
| `${reads}` | Both files, separated by a space (handy for tools that take R1 and R2) |
| `${reads[0]}` | Just R1 |
| `"${meta.id}.count.txt"` | Output names that can't clash between samples |

### Adding a field: a new map

```groovy
.map { meta, f -> tuple(meta + [read_pairs: f.text.trim().toInteger()], f) }
```

`meta + [read_pairs: …]` creates a **new** map with one extra key (Python: `{**meta, "read_pairs": n}`). Don't change a meta map in place: the same map object can be shared by several channels, and changing it in one place would silently change it everywhere.

### `join` with meta maps

Two process outputs that both start with `meta` can be joined directly: `COUNT_READS.out.join(GC_CONTENT.out)` gives `[meta, reads_file, gc_file]`, because the meta map is the key, and identical maps match.

!!! gotcha "Gotcha! Changed meta maps no longer join"
    After `meta + [read_pairs: 100]`, that map is **different** from the original, so it won't `join` with items that still carry the old one. Join first, then add fields, or join on `meta.id` (`map { meta, f -> tuple(meta.id, meta, f) }`).

!!! protip "Pro tip: read an nf-core module now"
    Open the FastQC module of nf-core: [modules/nf-core/fastqc/main.nf](https://github.com/nf-core/modules/blob/master/modules/nf-core/fastqc/main.nf). You'll recognise `tag "${meta.id}"`, `tuple val(meta), path(reads, …)`, named `emit:` outputs and a `stub:` block. A few things are new (`stageAs`, an `eval` output for the tool version, `topic:`), but you can read real nf-core code now.

---

## D. Guided exercise (about 25 min)

```quiz
id: 5.4-ex-steps
type: steps
concept: meta-map
label: "Mission steps"
steps:
  - "Run `meta.nf` and compare the `in:` and `out:` lines."
  - "Add the `batch` column (it's already in `samplesheet.csv`) to the meta map, and run again."
  - "Open the nf-core FastQC module (link in section C) and find `meta` in it."
  - "Run `to_meta.nf` (the challenge) as it is and read `qc_table.tsv`."
```

```quiz
id: 5.4-ex-a
type: single
concept: meta-map
question: "In `tuple val(meta), path(reads)` with paired-end data, what is `${reads}` inside the script?"
options:
  - text: "Only the R1 file."
  - text: "Both file names, separated by a space."
    correct: true
  - text: "The meta map."
explain: "A list of files becomes space-separated names, ready for commands like `fastqc ${reads}`. `${reads[0]}` and `${reads[1]}` pick one."
```

```quiz
id: 5.4-ex-b
type: single
concept: meta-map
question: "Your samplesheet gets a new column, `strandedness`. With the meta-map pattern, what must change?"
options:
  - text: "Every process input and output."
  - text: "Only the `map` that builds the meta map: add `strandedness: row.strandedness`. Processes that need it read `meta.strandedness`."
    correct: true
  - text: "Nothing at all: Nextflow adds columns automatically."
explain: "That's the whole point of the pattern: facts travel in one map, so adding one is a one-line change."
```

---

## E. Independent challenge

`to_meta.nf` works, but it carries `sample` and `condition` around **by position**. Look at `ROW`'s input: `tuple val(sample), val(condition), path(reads_txt), val(condition_again), path(gc_txt)`. Rewrite it with the meta-map pattern, and add a new column on the way:

1. Build `[meta, [R1, R2]]` from the samplesheet. `meta` holds `id`, `condition`, `batch` (a new column, already in `samplesheet.csv`) and `single_end`.
2. Every process **input** that carried `sample` and `condition` becomes `tuple val(meta), …`; `COUNT_READS` and `GC_CONTENT` also **emit** `tuple val(meta), path(…)`. Tag every task with `meta.id`.
3. `qc_table.tsv` gets **5 columns**: id, condition, **batch**, reads, GC%.

```groovy title="to_meta.nf (starter)"
--8<-- "module05_channels/lesson04_meta_maps/to_meta.nf"
```

The checker runs your pipeline on a new samplesheet (other names, other conditions and batches), checks the table, the tags, and that no process still takes `val(sample)` or `val(condition)`.

```quiz
id: 5.4-challenge
type: check
concept: meta-map
label: "Challenge: auto-checked"
check: 5.4-challenge
command: "bash check_to_meta.sh"
solution: includes/solutions/5.4/to_meta.nf
hint: "Start with the `map` in the workflow (section C shows the meta map). Then fix the processes one by one: inputs become `tuple val(meta), path(reads)`; use `${reads[0]}` where only R1 is needed and `${reads}` for both. After `counts.join(gcs)`, ROW receives `[meta, reads_txt, gc_txt]`."
explain: "Your pipeline now has the same shape as an nf-core pipeline: samplesheet → meta maps → modules that take and return `[meta, files]`."
```

---

## F. Knowledge check

```quiz
id: 5.4-q1
type: open
concept: meta-map
question: "Explain the meta-map pattern to a colleague, and give two advantages over plain tuples like `[sample, condition, r1, r2]`."
model: "Each item is `[meta, files]`, where meta is a map of facts about the sample (id, condition, …) and files are its data. Processes take and emit `tuple val(meta), path(...)`. Advantages: adding a new fact means adding one key, with no change to any process signature; the facts travel with the files through every step, so later steps (and reports) still know the condition or batch; processes become reusable modules with one standard interface (nf-core); names and tags come from meta.id, so outputs can't clash."
explain: "One interface, many pipelines."
```

```quiz
id: 5.4-q2
type: single
concept: meta-map
question: "Why write `meta + [read_pairs: n]` instead of changing `meta.read_pairs = n` in place?"
options:
  - text: "The `+` version is faster."
  - text: "The same meta map object can be shared by several channels; changing it in place would silently change it everywhere. `+` makes a new map."
    correct: true
  - text: "Maps in Nextflow can't have new keys."
explain: "Treat meta maps as read-only and make new ones. It's the same reason you avoid mutating shared dicts in Python."
```

---

## G. Summary

| Concept | Remember |
|---|---|
| Meta map | `[id: 'x', condition: 'y', …]`: facts about one sample |
| The pattern | Every item is `[meta, files]`; processes take/emit `tuple val(meta), path(…)` |
| `meta.id` | Tags and file names: `tag "${meta.id}"`, `"${meta.id}.bam"` |
| Adding a fact | `meta + [key: value]` makes a new map |
| `join` | Works on identical meta maps; changed maps don't match |

!!! flo "Level 1 theory complete!"
    You can now write processes, wire them with channels and operators, read samplesheets, carry metadata, configure software environments, publish results, resume and debug. Time to prove it: **Capstone 1** is a real QC pipeline, FastQC + MultiQC, on real data, built by you.

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="5.4"></div>
