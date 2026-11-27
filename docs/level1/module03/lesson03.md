---
lesson: "3.3"
module: 3
level: 1
---

# Lesson 3.3: Parameters and publishing results

!!! info "About this lesson"
    **You'll learn:**

    - how to make a pipeline configurable with a typed **`params` block** and `--name value` on the command line;
    - the **four places** a parameter can come from, and which one wins;
    - how to pass a parameter **into** a process;
    - how to **publish** final results out of `work/`: workflow outputs (the current way) and `publishDir` (what nf-core uses).

    **Why it matters:** nobody edits a pipeline's code to point it at new data. You run `nextflow run nf-core/rnaseq --input samples.csv --outdir results`. Today you build that interface for your own pipeline.

    **Time:** about 1.25 h · **Level:** Beginner · **Needs:** Lesson 3.2

    **Docs:** [Typed parameters](https://docs.seqera.io/nextflow/typed-parameters) · [Workflow outputs](https://docs.seqera.io/nextflow/workflow#outputs) · [`publishDir`](https://docs.seqera.io/nextflow/reference/process/directives/publish-dir) · [Parameter order (CLI)](https://docs.seqera.io/nextflow/cli)

!!! flo "Flo says"
    So far your results were buried in `work/a9/faa7b2…`. Today they get a proper home, and your pipeline gets knobs that anyone can turn without touching the code.

---

## A. Concept

### 1. Parameters: the knobs of a pipeline

```groovy title="main.nf (top)"
params {
    // Which FASTQ files to read (a glob pattern, so a String)
    reads: String = 'data/*.fastq'
}
```

- The `params` block **declares** every parameter the pipeline accepts, with a **type** and an optional **default**.
- In the workflow you use it as `params.reads`.
- On the command line you override it with **two dashes**: `--reads 'batch2/*.fastq'`. (One dash, like `-resume`, is for Nextflow's own options.)
- A parameter **without** a default is **required**: the run stops with *"Parameter `reads` is required but no value was provided"*.

Python analogy: the `params` block is like `argparse` with `type=` and `default=`, built in.

!!! info "Why `String` and not `Path`?"
    `'data/*.fastq'` is a **pattern** that `channel.fromPath` expands into many files, not one file path, so it's typed `String`. You'll use `Path` for parameters that point to exactly one file, such as a samplesheet (Module 5).

### 2. Four places, one winner

--8<-- "includes/anim/params_precedence.html"

From lowest to highest priority: the **script's default** → **`nextflow.config`** → a **`-params-file`** (YAML or JSON) → **`--name` on the command line**.

### 3. Publishing: getting results out of `work/`

`work/` is Nextflow's scratch space: one folder per task, hash-named, full of intermediate files. **Publishing** copies (or links) the files you care about into a clean results folder. The current way has two parts:

```groovy title="main.nf (end)"
workflow {
    main:
    reads_ch = channel.fromPath(params.reads)
    counts_ch = COUNT_READS(reads_ch)
    summary_ch = SUMMARISE(counts_ch.collect())

    publish:                 // (1)!
    counts = counts_ch
    summary = summary_ch
}

output {                     // (2)!
    counts {
        path 'counts'        // (3)!
    }
    summary {
        path '.'
    }
}
```

1. The `publish:` section **names** the channels whose files should be published. The workflow now needs a `main:` label before its normal code.
2. The top-level `output` block says **where** each named output goes.
3. A sub-folder of the output directory. `'.'` means the output directory itself.

The **output directory** is `results/` by default. Change it with `-output-dir` on the command line (one dash: it's a Nextflow option) or `outputDir = '…'` in `nextflow.config`.

---

## B. Demonstration

Here's the complete pipeline. Apart from the `params` and `publish`/`output` parts, it's the Lesson 3.2 pipeline (without the `sleep`, and with a `sort`):

```groovy title="main.nf"
--8<-- "module03_first_pipeline/lesson03_params_publish/main.nf"
```

```bash title="Terminal"
cd "$COURSE"/module03_first_pipeline/lesson03_params_publish
bash ../make_data.sh
nextflow run main.nf
```

```text title="Real output"
 N E X T F L O W   ~  version 26.10.7

Launching `main.nf` [angry_maxwell] revision: 629d02832c

executor >  local (4)
[d4/217305] COUNT_READS (1) | 3 of 3 ✔
[ff/1ae8e6] SUMMARISE       | 1 of 1 ✔

Outputs:

  …/lesson03_params_publish/results

  counts:
    - counts/sample1.count.tsv
    - counts/sample2.count.tsv
    - counts/sample3.count.tsv

  summary: summary.tsv
```

The new **Outputs** section lists everything that was published. Now use the knobs, without editing a single line:

```bash title="Terminal"
bash ../make_data.sh 2 500 batch2          # 2 smaller samples in batch2/
nextflow run main.nf --reads 'batch2/*.fastq' -output-dir results_batch2
cat results_batch2/summary.tsv
```

```text title="Real output (end)"
  counts:
    - counts/sample2.count.tsv
    - counts/sample1.count.tsv

  summary: summary.tsv

sample1	500
sample2	750
```

!!! gotcha "Gotcha! Quote your glob patterns"
    Write `--reads 'batch2/*.fastq'` **with quotes**. Without them, your shell expands the `*` before Nextflow sees it, and passes `batch2/sample1.fastq batch2/sample2.fastq` as separate words. `params.reads` gets only the first one. In a real test run, `--reads batch2/*.fastq` (no quotes) printed `COUNT_READS (1) | 1 of 1 ✔`: one sample instead of two, **with no error**.

### A typo is caught for you

```bash title="Terminal"
nextflow run main.nf --read 'batch2/*.fastq'
```

```text title="Real output"
 N E X T F L O W   ~  version 26.10.7

Launching `main.nf` [happy_blackwell] revision: 629d02832c

Parameter `read` was specified on the command line or params file but is not declared in the script or config
```

This is one reason to **declare** parameters in a `params` block: a misspelled option stops the run instead of being silently ignored.

---

## C. Code walkthrough

### Where did the files go?

```bash title="Terminal"
ls -l results results/counts
```

```text title="Real output (paths shortened)"
results:
total 0
drwxr-xr-x  5 mohamed  wheel  160 Nov 26 12:05 counts
lrwxr-xr-x  1 mohamed  wheel  182 Nov 26 12:05 summary.tsv -> …/lesson03_params_publish/work/ff/1ae8e647b0b0cf76c371c5efefb1d8/summary.tsv

results/counts:
total 0
lrwxr-xr-x  1 mohamed  wheel  188 Nov 26 12:05 sample1.count.tsv -> …/work/89/48ef557ad0b186f0e67a92d39b3ca2/sample1.count.tsv
lrwxr-xr-x  1 mohamed  wheel  188 Nov 26 12:05 sample2.count.tsv -> …/work/d4/217305bf713af884b3b02cbaf88561/sample2.count.tsv
lrwxr-xr-x  1 mohamed  wheel  188 Nov 26 12:05 sample3.count.tsv -> …/work/47/f10538d5031561f3ad61a998766977/sample3.count.tsv
```

Every published file is a **symbolic link** (`l` at the start, `->` to its target) into `work/`. That's the default: it's instant and costs no disk space. But you saw the danger in the Lesson 2.1 animation: **delete `work/` and every link breaks.**

For files you want to keep, publish real copies with `mode 'copy'`, either for one output:

```groovy title="main.nf (output block)"
    summary {
        path '.'
        mode 'copy'
    }
```

or for **all** outputs of the pipeline, in `nextflow.config`:

```groovy title="nextflow.config"
workflow.output.mode = 'copy'
```

!!! protip "Pro tip: links for big intermediates, copies for final results"
    BAM files are huge, and you can regenerate them. A MultiQC report or a count matrix is small and precious. Copy the precious ones, so you can clean `work/` safely.

### Try the four places yourself

`precedence.nf` only prints its parameter:

=== "Nextflow"

    ```groovy title="precedence.nf"
    --8<-- "module03_first_pipeline/lesson03_params_publish/precedence.nf"
    ```

=== "Python equivalent"

    ```python title="params.py"
    --8<-- "module03_first_pipeline/lesson03_params_publish/params.py"
    ```

    ```bash title="Terminal"
    python3 params.py
    echo '{"title": "from a params file"}' > params.json
    python3 params.py --params-file params.json
    python3 params.py --params-file params.json --title "from the command line"
    python3 params.py --titel oops                  # a typo
    ```

    ```text title="Real output"
    title = from the script
    title = from a params file
    title = from the command line
    usage: params.py [-h] [--title TITLE] [--params-file PARAMS_FILE]
    params.py: error: unrecognized arguments: --titel oops
    ```

!!! note "Where the analogy stops"
    argparse has no `nextflow.config` layer, and you write the file-merging yourself. Nextflow builds all four layers in, and also accepts JSON: `-params-file params.json` works too. Like argparse, it stops on a misspelled parameter such as `--titel`.

```bash title="Terminal"
nextflow run precedence.nf                                    # 1. script default
echo "params.title = 'from nextflow.config'" > nextflow.config
nextflow run precedence.nf                                    # 2. + config
echo "title: 'from params.yaml'" > params.yaml
nextflow run precedence.nf -params-file params.yaml           # 3. + params file
nextflow run precedence.nf -params-file params.yaml --title 'from the command line'   # 4.
rm nextflow.config params.yaml                                # tidy up afterwards!
```

```text title="Real output (the last line of each run)"
title = from the script
title = from nextflow.config
title = from params.yaml
title = from the command line
```

!!! gotcha "Gotcha! A forgotten `nextflow.config` changes every run"
    Nextflow reads `nextflow.config` from the launch folder **automatically**. If you leave the one from this experiment lying around, every later run in this folder gets its `params.title`. That's why the last command deletes it. When a pipeline behaves strangely, check for a `nextflow.config` you forgot about.

### Passing a parameter into a process

Inside a process you *could* write `${params.title}` directly, and older pipelines do. The recommended style is to pass it in as an **input**, like any other value:

```groovy title="the pattern"
process SUMMARISE {
    input:
    path counts
    val title               // a second input: one value

    …
}

workflow {
    …
    SUMMARISE(counts_ch.collect(), params.title)   // inputs in the same order
}
```

That keeps the process self-contained: it only knows what it's given, so it's easier to reuse and to test (Lesson 9.3).

### The other way to publish: `publishDir`

You'll meet this in **nf-core** pipelines and older tutorials. The Nextflow docs now say to use workflow outputs in new pipelines, but you need to be able to read both.

```groovy title="main_publishdir.nf"
--8<-- "module03_first_pipeline/lesson03_params_publish/main_publishdir.nf"
```

```text title="Real output: ls -l results results/counts"
results:
total 8
drwxr-xr-x  5 mohamed  wheel  160 Nov 26 12:06 counts
-rw-r--r--  1 mohamed  wheel   39 Nov 26 12:06 summary.tsv

results/counts:
total 24
-rw-r--r--  1 mohamed  wheel  13 Nov 26 12:06 sample1.count.tsv
-rw-r--r--  1 mohamed  wheel  13 Nov 26 12:06 sample2.count.tsv
-rw-r--r--  1 mohamed  wheel  13 Nov 26 12:06 sample3.count.tsv
```

| | Workflow outputs (`publish:` + `output {}`) | `publishDir` directive |
|---|---|---|
| Where it's written | Once, at the end of the script | Inside each process |
| Output folder | `-output-dir` / `outputDir` (default `results`) | Usually a `params.outdir` you define yourself |
| Default mode | Symlink | Symlink |
| Used by | New pipelines (Nextflow ≥ 25.10) | nf-core and older pipelines |

---

## D. Guided exercise (about 25 min)

```quiz
id: 3.3-ex-steps
type: steps
concept: params
label: "Mission steps"
steps:
  - "Run `main.nf`, then `ls -l results results/counts`. Spot the symlinks."
  - "Make `batch2` and run with `--reads 'batch2/*.fastq' -output-dir results_batch2`."
  - "Try the typo `--read` and read the error."
  - "Run the four `precedence.nf` commands, then delete `nextflow.config` and `params.yaml`."
  - "Run `main_publishdir.nf` (move `results/` aside first) and compare `ls -l` with the first run."
```

```quiz
id: 3.3-ex-a
type: single
concept: params
question: "`nextflow.config` sets `params.reads = 'old/*.fastq'`, and you run `nextflow run main.nf --reads 'new/*.fastq'`. Which files are read?"
options:
  - text: "`old/*.fastq`, because the config file is read first."
  - text: "`new/*.fastq`, because the command line has the highest priority."
    correct: true
  - text: "Both."
explain: "Command line > params file > config > script default."
```

```quiz
id: 3.3-ex-b
type: single
concept: publishing
question: "You published with the default mode, then ran `rm -rf work`. What happens to `results/summary.tsv`?"
options:
  - text: "Nothing: it's in `results/`, not in `work/`."
  - text: "It becomes a **broken link**: the file it pointed to was inside `work/`."
    correct: true
  - text: "Nextflow moves it back automatically."
explain: "The default publish mode is a symlink. Use `mode 'copy'` (per output) or `workflow.output.mode = 'copy'` (in the config) for results you want to keep."
```

```quiz
id: 3.3-ex-c
type: multi
concept: params
question: "Which of these are Nextflow's **own** options (one dash), not pipeline parameters? Tick all that apply."
options:
  - text: "`-resume`"
    correct: true
  - text: "`-output-dir`"
    correct: true
  - text: "`--reads`"
  - text: "`-params-file`"
    correct: true
explain: "One dash: options of `nextflow run` itself. Two dashes: your pipeline's own `params`."
```

---

## E. Independent challenge

Copy `main.nf` to **`report.nf`** and make these changes:

1. Add a parameter **`title`** (a `String`) with the default **`Read counts`**.
2. Pass it **into** `SUMMARISE` as a second input. The first line of `summary.tsv` must be `# <title>`, followed by the sorted counts.
3. Publish `summary.tsv` as a **real copy** (not a link), using `mode 'copy'` in the `output` block. The per-sample counts stay in `counts/`.

The checker runs `nextflow run report.nf --reads 'fresh/*.fastq' --title 'Batch 7' -output-dir published` on 4 new samples, then again without `--title`.

```quiz
id: 3.3-challenge
type: check
concept: params
label: "Challenge: auto-checked"
check: 3.3-challenge
command: "bash check_report.sh"
solution: includes/solutions/3.3/report.nf
hint: "A second input is just another line under `input:`, here `val title`. In the workflow, pass `params.title` as the second argument. In the script, `echo '# ${title}' > summary.tsv` writes the first line; then append the counts with `>>`."
explain: "You now have a pipeline with a real command-line interface: inputs, an option, and an output folder, which is exactly the shape of an nf-core pipeline."
```

---

## F. Knowledge check

```quiz
id: 3.3-q1
type: single
concept: params
question: "A parameter is declared as `reads: String` with **no default**. You run the pipeline without `--reads`. What happens?"
options:
  - text: "It runs with an empty string."
  - text: "It stops before running anything: the parameter is required."
    correct: true
  - text: "It runs on every file in the folder."
explain: "No default means required. You'll get: Parameter `reads` is required but no value was provided."
```

```quiz
id: 3.3-q2
type: open
concept: publishing
question: "Why does Nextflow publish results as symbolic links by default, and when should you switch to copies?"
model: "Links are instant and use no extra disk space, which matters for big files such as BAMs. But a link only works while its target exists in `work/`: cleaning `work/` breaks it. Switch to `mode 'copy'` for final results you want to keep or share (reports, tables, small summary files), and before you plan to delete `work/`."
explain: "On a cluster, `work/` often lives on scratch storage that gets purged, which is another reason to copy final results."
```

```quiz
id: 3.3-q3
type: single
concept: params
question: "Why is it better to pass `params.title` into a process as an input than to use `${params.title}` inside the process?"
options:
  - text: "It runs faster."
  - text: "The process then depends only on its inputs, so it's easier to reuse in another pipeline and to test."
    correct: true
  - text: "Processes can't read `params` at all."
explain: "Processes *can* read `params`, and older code does. But a self-contained process is easier to reuse, which matters a lot once you use modules (Module 6)."
```

---

## G. Summary

| Concept | Remember |
|---|---|
| `params { name: Type = default }` | Declares parameters; no default = required; typos are caught |
| `--name value` | Sets a parameter (two dashes) |
| Priority | script < `nextflow.config` < `-params-file` < command line |
| `publish:` + `output {}` | Name the channels to publish, then say where they go |
| Output directory | `results/` by default; `-output-dir` or `outputDir` changes it |
| Default publish mode | **Symlink** into `work/`; use `mode 'copy'` for results you keep |
| `publishDir` | The older per-process way; still everywhere in nf-core |

Next: **Lesson 3.4** looks inside `work/` one last time, and teaches the option you'll use more than any other: `-resume`.

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="3.3"></div>
