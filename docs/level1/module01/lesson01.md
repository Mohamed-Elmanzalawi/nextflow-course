---
lesson: "1.1"
module: 1
level: 1
---

# Lesson 1.1: What is Nextflow, and why do bioinformaticians use it?

!!! info "About this lesson"
    **You'll learn:**

    - what a *workflow* and a *workflow manager* are;
    - which problems Nextflow solves that Bash scripts don't;
    - how Nextflow compares with Snakemake, CWL/WDL and Galaxy.

    **Why it matters:** every design choice you'll meet later makes sense once you know which problem it solves. Examples are the strange `work/` directories, channels, and processes that can't see each other's files.

    **Time:** about 1.5 h · **Level:** Beginner · **Needs:** a terminal (no Nextflow yet)

    **Docs:** [Nextflow overview](https://docs.seqera.io/nextflow/overview) · [EMBL-EBI Introduction to Nextflow](https://www.ebi.ac.uk/training/online/courses/nextflow/introduction-to-nextflow/) · [Hello Nextflow](https://training.nextflow.io/latest/hello_nextflow/)

!!! flo "Flo says"
    Welcome to your first page! Today we do something a little unusual: **first you'll feel the pain** of running a pipeline with plain Bash, and **then you'll meet the cure**.

    No installation needed yet. All you need is a terminal and a bit of curiosity.

---

## A. Concept

### Workflows and workflow managers

A **workflow**, also called a **pipeline**, is an ordered set of steps in which each step's output feeds the next. You already run workflows by hand, for example:

```text
fastqc  →  fastp  →  bwa mem  →  samtools sort  →  bcftools call
```

A **workflow manager** is a program that *runs* those steps for you. You describe the steps and how data moves between them. The manager then decides:

- **when** each step can run, because its inputs are ready;
- **where** it runs: your laptop, a SLURM node, or the cloud;
- **with what software**: a container or a conda environment for each step;
- **what to do on failure**: retry, skip, or stop cleanly;
- **what's already done**, so a rerun doesn't repeat finished work.

!!! analogy "Real-life analogy: a restaurant kitchen"
    | Kitchen | Pipeline world |
    |---|---|
    | The **recipe** | Your **workflow** (the steps and their order) |
    | One **cooking station** (grill, salad, dessert) | A **process** |
    | Cooking **one** order at a station | A **task** |
    | The **ticket rail** passing orders between stations | A **channel** |
    | The **head chef** who decides who cooks what, when, and re-fires a burnt dish | The **workflow manager** |
    | Your kitchen vs a huge catering hall | Your laptop vs a SLURM cluster: same recipe, bigger kitchen |

    A Bash script is like **one cook making every dish alone, start to finish, one at a time**. If they burn dish 157, they throw everything away and start again from dish 1.

!!! question "Scripting language vs workflow manager"
    Bash and Python describe **how to do one thing**. A workflow manager handles **running many things**: scheduling, parallelism, retries, caching, logging and portability.

    Nextflow doesn't replace your Bash. **Your Bash commands go inside Nextflow.**

### What Nextflow is

Nextflow is two things in one:

1. **A language** for describing workflows. It's built on Groovy, which runs on Java, and the current dialect is called **DSL2**.
2. **An engine** that runs those workflows on many platforms.

It was created at the Centre for Genomic Regulation in Barcelona and is now developed by Seqera. It's open source, and the **nf-core** community pipelines are built with it.

!!! funfact "Fun fact"
    Nextflow runs on the **Java Virtual Machine**. That's why Lesson 2.2 installs Java before Nextflow itself.

    Nextflow was introduced in a 2017 *Nature Biotechnology* paper: [Di Tommaso et al., "Nextflow enables reproducible computational workflows"](https://doi.org/10.1038/nbt.3820). Browse the community's ready-made pipelines at [nf-co.re/pipelines](https://nf-co.re/pipelines).

Nextflow uses three core ideas. You'll spend Modules 3–5 on them.

| Idea | What it is | Analogy |
|---|---|---|
| **Process** | One step, e.g. "run FastQC on a FASTQ file". Each time it runs on an input, that run is called a **task**. | A function |
| **Channel** | A queue that carries data (files, values) from one process to the next | A conveyor belt |
| **Dataflow** | A process starts as soon as its inputs arrive. You never write "now run step 2". | A factory line |

### The same three-sample job, two ways

Watch the two animations side by side. Watch the clock in each.

--8<-- "includes/anim/bash_sequential.html"

--8<-- "includes/anim/nextflow_dataflow.html"

In the Nextflow version, the three tasks run **at the same time**, limited only by your CPUs or your cluster. `SUMMARISE` starts by itself once all three results exist. Nobody told it to wait.

### Which problems does it solve?

| Problem | Bash script | Nextflow |
|---|---|---|
| Parallelism | Sequential unless you write `&`/`wait` or `xargs -P` and manage it yourself | Automatic: independent tasks run in parallel |
| Failure at sample 157 of 200 | Rerun everything, or hand-edit the script | `-resume` reuses every finished task |
| Laptop → SLURM → cloud | Rewrite the script with `sbatch` and job dependencies | Change the config: `-profile slurm` |
| Software versions | Whatever happens to be on `$PATH` | A container or conda environment for each step |
| Tasks overwriting each other's files | Common | Each task runs in its own isolated directory |
| Knowing what ran | Your memory and `history` | Logs, execution reports, timelines, trace files |

### How it compares with other tools

| Tool | Style | Key difference |
|---|---|---|
| **Bash / Make** | Scripts or file rules | No built-in containers, cluster support or resume (Make can skip outputs that are already up to date, but that's all) |
| **Snakemake** | Python-based rules | Starts from the **final files you ask for** and works **backward** to decide what to run |
| **Nextflow** | Groovy-based dataflow | **Pushes data forward** through channels. Strong at running on clusters and clouds. Large nf-core community. |
| **CWL / WDL** | Declarative specifications | Describe the workflow but need a separate engine to run it (e.g. Cromwell, Toil). Very portable, more verbose. |
| **Galaxy** | Web interface | Point-and-click. Less flexible for developing new pipelines. |

Snakemake and Nextflow are both excellent. Nextflow is often chosen for large-scale HPC or cloud runs and to use nf-core's ready-made pipelines.

---

## B. Demonstration

You don't need Nextflow yet. This demo shows the **problems** Nextflow solves, using a typical Bash pipeline. The lesson folder holds two files:

- `make_data.sh` creates tiny fake FASTQ files;
- `naive_pipeline.sh` counts reads per sample, with `sleep 2` standing in for a slow tool.

```bash title="Terminal"
cd ~/Desktop/Projects/learning_nextflow/module01_intro/lesson01_what_is_nextflow
bash make_data.sh
time bash naive_pipeline.sh
```

??? predict "Predict before you run: how long will it take, and what will the summary say?"
    Here is the real output from a test run on this machine:

    ```text title="Real output"
    Created 3 FASTQ files with 1000 reads each in data/
    [12:47:40] Processing sample1
    [12:47:42] Processing sample2
    [12:47:44] Processing sample3
    [12:47:46] Done. Summary:
    sample1	1000
    sample2	1000
    sample3	1000
    bash naive_pipeline.sh  0.04s user 0.04s system 1% cpu 6.127 total
    ```

    Your timestamps will differ. The **~6 s total** is what matters: three 2-second steps, one after another, just like the Bash animation above. Did you guess right?

---

## C. Code walkthrough

### The data generator

```bash title="module01_intro/lesson01_what_is_nextflow/make_data.sh" linenums="1"
--8<-- "module01_intro/lesson01_what_is_nextflow/make_data.sh"
```

This writes `n_samples` FASTQ files, 1000 reads each by default, with random 50 bp sequences. You don't need to study it; it only creates test data.

### The Bash pipeline

```bash title="module01_intro/lesson01_what_is_nextflow/naive_pipeline.sh" linenums="1"
--8<-- "module01_intro/lesson01_what_is_nextflow/naive_pipeline.sh"
```

You know Bash already, so focus on **what's missing**:

| Line | Code | What's missing or fragile |
|---|---|---|
| 3 | `set -euo pipefail` | Good practice, but one bad sample stops the **whole** run |
| 5 | `mkdir -p results` | Every sample writes to **one shared folder**; nothing separates them |
| 7 | `for fq in data/*.fastq` | **One sample at a time**, in order |
| 10 | `sleep 2` | The "slow tool": its time adds up **linearly** with sample count |
| 11 | `awk ... > results/...` | No record of which samples finished; a half-written file looks like a finished one |
| 14 | `cat results/*.count.tsv` | Summarises **whatever happens to be in the folder**, including leftovers from older runs |

!!! gotcha "Gotcha! An empty folder doesn't mean an empty loop"
    If `data/` contains no `.fastq` files, Bash does **not** skip the loop. By default an unmatched glob stays as the literal text `data/*.fastq`, so the loop runs once on a file that doesn't exist, and you get a confusing `awk` error.

    Nextflow's `channel.fromPath` simply emits nothing when nothing matches. You can also make it fail loudly with the option `checkIfExists: true`, which you'll meet in Module 5.

!!! protip "Pro tip"
    `set -euo pipefail` is a great habit, but it only makes the script **stop**. It doesn't make it **recover**. Recovery (retry, resume, skip finished work) is exactly what a workflow manager adds.

    Nextflow runs each task's script with Bash's `-e` and `-u` options by default. Many pipelines, including nf-core ones, also add `pipefail` in their config. You'll see how in Module 7.

### The same pipeline in Nextflow (preview)

!!! warning "Preview: read it, don't memorise it"
    You'll run it yourself in Lesson 3.2. It **has been tested** with Nextflow 26.10.7: the three `COUNT_READS` tasks ran in parallel, and the whole run took about 5 s, including Nextflow's own start-up.

    Click the :material-plus-circle: markers for explanations.

```groovy title="main.nf"
params.reads = 'data/*.fastq' // (1)!

process COUNT_READS { // (2)!
    input:
    path fq // (3)!

    output:
    path "${fq.baseName}.count.tsv" // (4)!

    script: // (5)!
    """
    sleep 2
    awk -v s=${fq.baseName} 'END{print s"\t"NR/4}' ${fq} > ${fq.baseName}.count.tsv
    """
}

process SUMMARISE {
    publishDir 'results', mode: 'copy' // (6)!

    input:
    path counts // (7)!

    output:
    path 'summary.tsv'

    script:
    """
    cat ${counts} > summary.tsv
    """
}

workflow { // (8)!
    reads_ch  = channel.fromPath(params.reads) // (9)!
    counts_ch = COUNT_READS(reads_ch) // (10)!
    SUMMARISE(counts_ch.collect()) // (11)!
}
```

1. A **pipeline parameter**. You can override it on the command line without editing the script: `nextflow run main.nf --reads 'other/*.fastq'`.
2. A **process** is one step. Process names are written in CAPITALS by convention.
3. Each **task** of this process receives **one** file. Nextflow stages it into the task's own private folder.
4. The file this task **promises** to produce. If it's missing, the task fails loudly instead of silently carrying on. `${fq.baseName}` is the file name without its extension, e.g. `sample1`.
5. The `script:` block is ordinary Bash, run inside the task's isolated directory under `work/`.
6. A **directive** that copies the final output into `results/`. Intermediate files stay in `work/`.
7. This process receives **all** the count files at once, because of `collect()` in line 11.
8. The `workflow` block is the **wiring**: it connects processes with channels. It contains no loop and no "wait".
9. A **channel factory** that creates a channel emitting one item per matching file: `sample1.fastq`, `sample2.fastq`, `sample3.fastq`.
10. Calling a process on a channel: **3 items in → 3 tasks**, run in parallel. The result is a new channel of count files.
11. `collect()` is an **operator**. It waits until the channel is finished, then emits one list of every item. So `SUMMARISE` can't start early, even though nobody wrote "wait".

---

## D. Guided exercise (about 20 min)

Do these steps in the lesson folder, then answer the questions below. Your answers are saved automatically.

```quiz
id: 1.1-ex-steps
type: steps
concept: running-the-demo
label: "Mission steps"
steps:
  - "Run the demo from section B and note the total time."
  - |
    Make 10 samples and time the run again. **Guess the time before you run it!**

    ```bash
    rm -rf data results
    bash make_data.sh 10
    time bash naive_pipeline.sh
    ```
  - |
    Simulate a crash partway through:

    ```bash
    rm -rf results
    chmod 000 data/sample7.fastq      # make one input unreadable
    bash naive_pipeline.sh
    ls -l results/
    ```
  - |
    Fix it and rerun. Watch which samples get processed again:

    ```bash
    chmod 644 data/sample7.fastq
    bash naive_pipeline.sh
    ```
```

```quiz
id: 1.1-ex-a
type: number
concept: sequential-execution
question: "**(a)** About how many seconds did the 10-sample run take?"
answer: 20
tolerance: 3
unit: seconds
explain: "Each sample waits for the previous one: 10 × 2 s ≈ 20 s. The time grows **linearly** with the number of samples. With 3 samples it was ~6 s."
```

```quiz
id: 1.1-ex-b
type: multi
concept: glob-order-and-partial-files
question: "**(b)** After the crash, which files were in `results/`? Tick all that apply."
hint: "Files are processed in alphabetical glob order, so `sample10` comes before `sample2`. Also look closely at the **size** of each file in `ls -l`."
options:
  - text: "`sample1.count.tsv`"
    correct: true
  - text: "`sample10.count.tsv`"
    correct: true
  - text: "`sample2.count.tsv` … `sample6.count.tsv`"
    correct: true
  - text: "`sample7.count.tsv` (an **empty**, 0-byte file)"
    correct: true
  - text: "`sample8.count.tsv` and `sample9.count.tsv`"
  - text: "`summary.tsv`"
explain: |
  Order was sample1 → sample10 → sample2 … sample6 → **sample7 (crash)**. The surprise is that **`sample7.count.tsv` exists but is empty**. The shell creates the output file for `>` *before* `awk` runs, and `awk` then fails.

  A crashed step leaves a file that **looks finished**. Remember this one: it's exactly why Nextflow runs every task in its own folder and only treats a task as done when it exits successfully.
```

```quiz
id: 1.1-ex-c
type: number
concept: cost-of-no-resume
question: "**(c)** The rerun redid every sample. If each sample took **2 hours** on your cluster, how many hours of *already finished* work were thrown away?"
hint: "How many samples had finished successfully before sample7 crashed?"
answer: 14
tolerance: 0
unit: hours
explain: "7 samples (sample1, sample10, sample2–sample6) had finished, and all of them were redone: 7 × 2 h = **14 h** wasted. Scale that to 200 samples crashing at sample 157 and you lose about 13 days. Nextflow's `-resume` would redo **only** the failed task."
```

---

## E. Independent challenge

Copy the script to `naive_pipeline_v2.sh` in the lesson folder and change it so that:

1. samples are processed **in parallel**;
2. a rerun **skips samples that already have a finished output**.

Then run the checker. It tests your script on fresh data in a temporary folder and updates this page automatically.

```quiz
id: 1.1-challenge
type: check
concept: parallelism-and-resume
label: "Challenge: auto-checked"
check: 1.1-challenge
command: "bash check_challenge.sh"
solution: includes/solutions/1.1/naive_pipeline_v2.sh
hint: "Bash runs a command in the background with `&`, and `wait` waits for background jobs. For skipping, test whether the output already exists, but remember what you found in (b): an empty file can look \"finished\"."
explain: |
  **Why this solution works:** `&` plus `wait` gives parallelism. `-s` skips outputs that exist **and are non-empty**. Writing to a `.tmp` file and then using `mv` means a killed run never leaves a half-written result.

  **What's still missing**, compared with a workflow manager:

  - No limit on concurrency: 200 samples means 200 processes at once on your laptop.
  - A bare `wait` hides failures, so the script has to track every PID by hand.
  - It doesn't notice **changed inputs**. Edit a FASTQ and the old result is still "done". Nextflow hashes inputs and scripts.
  - No isolation: every task writes into one shared folder.
  - No software management: whichever `awk` is on `$PATH` gets used.
  - No cluster support and no retries.
  - No logs, reports or provenance.
```

```quiz
id: 1.1-fragile
type: open
concept: workflow-manager-benefits
question: "List **at least four things** that are still fragile or missing in your v2 script, compared with what a workflow manager gives you."
model: |
  Any four of these:

  1. **Unlimited parallelism.** No cap on how many jobs run at once, so it can overload the machine.
  2. **Silent failures.** A bare `wait` returns 0 even if a sample failed.
  3. **Changed inputs aren't detected.** "Output exists" doesn't mean "output is up to date".
  4. **Half-written files.** Without the `.tmp` + `mv` trick, an interrupted write looks finished.
  5. **No isolation.** Every sample writes into one shared folder.
  6. **No software pinning.** Results depend on whatever tools are installed.
  7. **No retries** and no cluster or cloud execution.
  8. **No record of what ran**: no logs, timings or provenance.
```

---

## F. Knowledge check

Short answers are fine. Type them, compare with the model answer, and rate yourself honestly.

```quiz
id: 1.1-q1
type: open
concept: workflow-manager
question: "What is the difference between a scripting language (Bash or Python) and a workflow manager?"
model: "A scripting language describes **how to do one thing**: the commands. A workflow manager handles **running many things**: when each step runs, where it runs, with which software, what to do on failure, and what's already done. In Nextflow, your Bash still does the work *inside* each process."
```

```quiz
id: 1.1-q2
type: single
concept: dataflow
question: "In the Nextflow preview, nobody wrote \"wait for all samples\". Why doesn't `SUMMARISE` start too early?"
options:
  - text: "Nextflow always runs processes in the order they're written in the file."
  - text: "`collect()` emits its single list only after the channel has delivered **every** item, and `SUMMARISE` can't start until its input arrives."
    correct: true
  - text: "`publishDir` makes Nextflow wait until all files are copied."
  - text: "Nextflow runs everything sequentially by default."
explain: "That's **dataflow**: a process starts when its inputs are ready. `collect()` makes `SUMMARISE`'s input ready only once all `COUNT_READS` results exist. The order of code in the file doesn't matter."
```

```quiz
id: 1.1-q3
type: open
concept: portability
question: "You want to move `naive_pipeline.sh` from your Mac to SLURM. Name two things you'd have to change in the Bash script. What would change in the Nextflow version?"
model: "**Bash:** wrap each sample in an `sbatch` job (with `#SBATCH` resources), handle job dependencies so the summary waits (`--dependency=afterok:...`), and possibly change paths or modules for the software. **Nextflow:** the script doesn't change at all. You switch the **executor in the configuration** (for example `-profile slurm` with `process.executor = 'slurm'`) and Nextflow submits and tracks the jobs itself."
```

```quiz
id: 1.1-q4
type: single
concept: dataflow
question: "True or false: *\"Nextflow decides what to run by starting from the final output file and working backward.\"*"
options:
  - text: "True"
  - text: "False"
    correct: true
explain: "False. Working **backward** from requested output files is how **Snakemake** (and Make) work. Nextflow works **forward**: data is pushed through channels, and each process runs when its inputs arrive."
```

```quiz
id: 1.1-q5
type: open
concept: resume
question: "A 200-sample run crashes at sample 157 after three days. What happens when you rerun the Bash script? What *should* happen with a workflow manager?"
model: "**Bash:** it starts again from sample 1 and redoes the 156 finished samples, losing about 3 days. It may also trip over a half-written output from sample 157. **Workflow manager:** with `nextflow run ... -resume`, every task that finished successfully is reused from the cache, so only sample 157 (and anything downstream of it) runs again."
```

---

## G. Summary

| Term | Meaning |
|---|---|
| Workflow / pipeline | Chained analysis steps |
| Workflow manager | Runs the steps: scheduling, parallelism, retries, caching, portability |
| Process / task | A step definition / one run of that step on one input |
| Channel | A queue carrying data between processes |
| Operator | A function that transforms a channel, e.g. `collect()` |
| Dataflow | Steps run when their inputs are ready; no explicit ordering |
| DSL2 | The current Nextflow language dialect |

**Commands used:** `time`, `chmod`, `&`/`wait`. No Nextflow commands yet.

**Further reading:** Di Tommaso P. et al. (2017), *Nextflow enables reproducible computational workflows*, Nature Biotechnology 35:316–319.

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="1.1"></div>
