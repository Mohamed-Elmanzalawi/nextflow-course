---
lesson: "1.2"
module: 1
level: 1
---

# Lesson 1.2: Reproducibility, portability, scalability, and thinking in dataflow

!!! info "About this lesson"
    **You'll learn:**

    - what makes an analysis **reproducible**, and the sneaky ways it isn't;
    - how Nextflow keeps **what** your pipeline does separate from **where** it runs (portability);
    - why the same pipeline handles 3 or 3,000 samples (scalability);
    - how to read a pipeline as a **dataflow graph**.

    **Why it matters:** these three words appear in every Nextflow paper and talk. After this lesson you'll know exactly which Nextflow feature delivers each one, and you'll have caught a real reproducibility bug with your own hands.

    **Time:** about 1.5 h · **Level:** Beginner · **Needs:** a terminal (no Nextflow yet)

    **Docs:** [Nextflow overview](https://docs.seqera.io/nextflow/overview) · [Executors](https://docs.seqera.io/nextflow/executor) · [Caching and resuming](https://docs.seqera.io/nextflow/cache-and-resume)

!!! flo "Flo says"
    Last lesson you saw Bash lose 14 hours of work. Today's villain is sneakier: a script that **finishes successfully** and quietly gives a **different answer** depending on who runs it. Let's catch it red-handed!

---

## A. Concept

### Reproducibility: same inputs → same results, every time

A result is **reproducible** when someone else (or you, in six months) can rerun the analysis and get the **same output**. Three things must stay the same:

| What must stay fixed | What goes wrong | How Nextflow helps |
|---|---|---|
| **The data** | Files edited by hand, a different reference version | Inputs are tracked by content: change a file and the affected tasks rerun |
| **The code** | "Which version of the script did I use?" | Pipelines live in Git. You can run an exact version: `nextflow run <repo> -r v1.2.0` |
| **The environment** | Different tool versions, OS, **settings like the locale** | Each process can run in its own **container** or **conda** environment |

Nextflow also **records** what happened: logs, an execution report, a timeline and a trace. You'll use those in Modules 7 and 8.

!!! analogy "Real-life analogy: a recipe that works only in your kitchen"
    Your grandmother's cake recipe says "one cup of flour". Her cup holds 200 ml and yours holds 250 ml. Same recipe, same ingredients, different cake, and **nobody gets an error message**.

    A **container** is like shipping the recipe *together with her measuring cups and her oven*.

### Portability: separate *what* from *where*

In Nextflow, the **pipeline script** (`main.nf`) says **what** to do. The **configuration** says **where and how** to run it. To move from your laptop to SLURM, you don't touch the pipeline. You change one setting, the **executor**: the component that actually launches tasks.

--8<-- "includes/anim/portability.html"

Some executors Nextflow supports: `local` (default), `slurm`, `sge`, `pbs`, `lsf`, `awsbatch`, `google-batch`, `azurebatch`, `k8s`. You'll configure SLURM for your own cluster in Module 7.

### Scalability: from 3 samples to 3,000

Each sample becomes an independent **task**, so Nextflow can run as many at once as the executor allows. On your laptop that means your CPU cores; on SLURM, it means jobs in the queue. The pipeline code is identical for 3 samples or 3,000.

!!! gotcha "Gotcha! Parallel doesn't mean ordered"
    When tasks run in parallel, they **finish in whatever order they finish**. Never write a pipeline that assumes sample 1's result arrives before sample 2's. Module 5 shows how to sort, join and group results properly.

### Thinking in dataflow

In Lesson 1.1 you met **dataflow**: a step runs when its inputs are ready. Here's the best everyday example.

!!! analogy "Real-life analogy: a spreadsheet"
    In a spreadsheet, cell `C1` holds `=A1+B1`. You never tell it "now calculate C1". It recalculates **automatically** whenever `A1` or `B1` changes.

    | Spreadsheet | Nextflow |
    |---|---|
    | A cell with a formula | A **process** |
    | A reference like `A1` | A **channel** connecting processes |
    | Typing a new value in `A1` | A new file arriving in a channel |
    | Dependent cells recalculating | Downstream tasks starting |

Put together, the processes and channels of a pipeline form a **DAG** (*directed acyclic graph*): boxes connected by arrows that never loop back. Here's a typical small pipeline:

--8<-- "includes/anim/dag_execution.html"

`FASTQC` and `TRIM` both need only the reads, so they **start at the same time**. `ALIGN` waits for `TRIM`. `MULTIQC` waits for everything. Nextflow works this out from the connections; the order you write the lines in doesn't matter.

!!! funfact "Fun fact"
    Nextflow can draw this graph for you from a real pipeline with the `-with-dag` option. You'll use it in Module 7.5. Docs: [workflow diagram](https://docs.seqera.io/nextflow/reports).

---

## B. Demonstration: catch a reproducibility bug

Your lab has an expression table, and a shared reference folder has a gene annotation table that someone **pre-sorted on the cluster**. A tiny script joins them to add a chromosome column. The lesson folder holds:

- `make_data.sh` creates the two small tables;
- `annotate.sh` sorts your table and `join`s it with the annotation.

```bash title="Terminal"
cd ~/Desktop/Projects/learning_nextflow/module01_intro/lesson02_reproducibility
bash make_data.sh
LC_ALL=C bash annotate.sh
LC_ALL=en_US.UTF-8 bash annotate.sh
```

`LC_ALL` sets the **locale**: language and sorting rules. Your terminal, your colleague's terminal and a cluster node may all have different locales without anyone noticing.

??? predict "Predict before you run: will both runs give the same answer?"
    Real output from this Mac:

    ```text title="Real output"
    Created data/expression.tsv (6 genes) and data/annotation.tsv (6 genes)
    Annotated 6 of 6 genes:
    ACTB	980	chr7
    BRCA1	15	chr17
    Gapdh	870	chr12
    MYC	230	chr8
    Tp53	120	chr17
    egfr	45	chr7
    Annotated 5 of 6 genes:
    ACTB	980	chr7
    BRCA1	15	chr17
    Gapdh	870	chr12
    MYC	230	chr8
    Tp53	120	chr17
    ```

    Same data, same script, and **`egfr` silently disappears** in the second run, which still finishes with exit code 0. No error, no warning.

---

## C. Code walkthrough

```bash title="module01_intro/lesson02_reproducibility/annotate.sh" linenums="1"
--8<-- "module01_intro/lesson02_reproducibility/annotate.sh"
```

| Line | Code | What's going on |
|---|---|---|
| 8 | `sort data/expression.tsv` | `sort` orders lines using the **current locale's rules**. In `C`, uppercase comes before lowercase (`Tp53` < `egfr`). In `en_US.UTF-8`, case is mostly ignored, so `egfr` lands in a different place. |
| 9 | `join … data/annotation.tsv` | `join` walks through both files **in step**, assuming they're sorted the same way. The annotation was sorted with `C` rules. When the two orders disagree, `join` misses the genes that are out of place, and it says nothing about it. |

Watch `join` walk through the two files step by step:

--8<-- "includes/anim/join_bug.html"

!!! protip "Pro tip"
    Many classic bioinformatics bugs are **environment** bugs: `sort` and `join` with different locales, different `samtools` versions with different defaults, or a reference genome named `chr1` vs `1`. Containers and pinned versions (Module 2.3 and Module 9) take whole classes of these bugs off the table.

---

## D. Guided exercise (about 20 min)

```quiz
id: 1.2-ex-steps
type: steps
concept: running-the-demo
label: "Mission steps"
steps:
  - "Run the demo in section B with both locales."
  - |
    Compare the two results directly:

    ```bash
    LC_ALL=C bash annotate.sh > run_C.txt
    LC_ALL=en_US.UTF-8 bash annotate.sh > run_US.txt
    diff run_C.txt run_US.txt
    ```
  - |
    Look at the two sort orders side by side:

    ```bash
    LC_ALL=C sort data/expression.tsv
    LC_ALL=en_US.UTF-8 sort data/expression.tsv
    ```
  - |
    Check which locale **your own terminal** uses by default:

    ```bash
    locale
    ```
```

```quiz
id: 1.2-ex-a
type: number
concept: environment-reproducibility
question: "How many genes were **lost** in the `en_US.UTF-8` run?"
answer: 1
tolerance: 0
unit: genes
explain: "One gene, `egfr`, was dropped. One gene might not sound like much, but it's **silent**: no error, exit code 0. In a real 20,000-gene table, hundreds of genes can vanish this way."
```

```quiz
id: 1.2-ex-b
type: single
concept: environment-reproducibility
question: "Why did `egfr` get lost?"
options:
  - text: "`egfr` is missing from the annotation file."
  - text: "The two files were sorted with **different locale rules**, and `join` assumes both use the same order."
    correct: true
  - text: "`join` can't handle lowercase gene names."
  - text: "The script crashed halfway through."
explain: "The annotation was sorted with `C` rules (uppercase before lowercase) on the cluster. On your machine the expression table was sorted with `en_US` rules (case mostly ignored). `join` walks both files in step, so a gene that's \"out of place\" is silently skipped."
```

```quiz
id: 1.2-ex-c
type: multi
concept: reproducibility-pillars
question: "Which of these could make the **same script on the same data** give different results on two machines? Tick all that apply."
options:
  - text: "A different version of a tool (e.g. `samtools` 1.9 vs 1.21)"
    correct: true
  - text: "A different locale setting"
    correct: true
  - text: "A different default parameter in a newer tool release"
    correct: true
  - text: "The colour scheme of your terminal"
explain: "Tool versions, their defaults and environment settings like the locale all change behaviour. This is why Nextflow pipelines pin the software environment **per process** with containers or conda. Your terminal colours, luckily, don't matter."
```

---

## E. Independent challenge

Copy `annotate.sh` to `annotate_fixed.sh` and fix it so that it gives **exactly the same, complete output no matter which locale the person running it uses**. The checker runs your script under three locales: `C`, `en_US.UTF-8` and `ja_JP.UTF-8`.

```quiz
id: 1.2-challenge
type: check
concept: environment-reproducibility
label: "Challenge: auto-checked"
check: 1.2-challenge
command: "bash check_challenge.sh"
solution: includes/solutions/1.2/annotate_fixed.sh
hint: "Two ways to get *all six genes*: sort **both** files yourself, or control the sorting rules. Only one of them also makes the output **identical** in every locale. Which setting does the checker change between runs?"
explain: |
  **Why this works:** setting `export LC_ALL=C` **inside** the script pins the sorting rules, so the result no longer depends on the caller's environment. `C` is also the order the annotation was sorted in.

  A "half fix" that sorts **both** files in the caller's locale finds all six genes, but the **order** of the output still changes with the locale. Downstream tools, `diff`s and checksums would see "different" results. The checker catches this.

  The Nextflow way goes one step further: run the step in a **container**, so the whole environment (tools, versions, settings) is fixed, not just one variable.
```

```quiz
id: 1.2-q-env
type: open
concept: environment-reproducibility
question: "Setting `LC_ALL=C` fixed **one** variable. Name two other things about the environment that could still differ between your Mac and the cluster, and how Nextflow can fix them."
model: "For example: (1) **tool versions**: `sort`/`join` on macOS are BSD tools, while on Linux they're GNU, with different behaviour and options; (2) **other software** like `samtools` or Python packages, and their default parameters. Nextflow fixes these by running each process inside a **container** (Docker/Apptainer) or a pinned **conda** environment, so every machine uses the exact same software."
```

---

## F. Knowledge check

```quiz
id: 1.2-q1
type: single
concept: portability
question: "You move a Nextflow pipeline from your Mac to your SLURM cluster. What do you change?"
options:
  - text: "Rewrite each process to call `sbatch`."
  - text: "Only the configuration, e.g. the executor (`-profile slurm`). The pipeline script stays the same."
    correct: true
  - text: "Convert the pipeline to a Snakefile."
  - text: "Nothing at all, not even configuration."
explain: "Nextflow keeps **what** (the pipeline) separate from **where** (the configuration and executor). You'll write a SLURM profile for your own cluster in Module 7."
```

```quiz
id: 1.2-q2
type: number
concept: dataflow-dag
question: "Using the DAG in section A with **4 samples**: `FASTQC`, `TRIM` and `ALIGN` each run once per sample, and `MULTIQC` runs once. How many **tasks** run in total?"
answer: 13
tolerance: 0
unit: tasks
explain: "4 (FASTQC) + 4 (TRIM) + 4 (ALIGN) + 1 (MULTIQC) = **13 tasks**. A process is the recipe; a task is one run of it on one input."
```

```quiz
id: 1.2-q3
type: number
concept: dataflow-dag
question: "Same pipeline, 4 samples, plenty of CPUs. How many tasks can be **running at the very start**, before anything has finished?"
answer: 8
tolerance: 0
unit: tasks
explain: "`FASTQC` and `TRIM` both need only the reads, so all 4 + 4 = **8** start immediately. `ALIGN` waits for `TRIM`, and `MULTIQC` waits for everything."
```

```quiz
id: 1.2-q4
type: single
concept: dataflow-dag
question: "In a workflow block, the line calling `TRIM` is written **above** the line calling `FASTQC`. Both only use the reads channel. Which runs first?"
options:
  - text: "`TRIM`, because it's written first."
  - text: "`FASTQC`, because QC always comes first."
  - text: "Neither: both start together, because they only depend on the reads."
    correct: true
explain: "In dataflow, **dependencies** decide the order, not the line order. Independent processes run at the same time."
```

```quiz
id: 1.2-q5
type: open
concept: dataflow
question: "Explain the spreadsheet analogy for dataflow in your own words."
model: "A spreadsheet cell with a formula (like `=A1+B1`) recalculates automatically when the cells it refers to change; you never say \"now compute this cell\". In Nextflow, a **process** is like the formula cell and **channels** are like the references: when new data arrives on a channel, the process runs on it automatically, and its results flow on to the next processes."
```

---

## G. Summary

| Term | Meaning |
|---|---|
| Reproducibility | Same inputs + same code + same environment → same results |
| Portability | The same pipeline runs anywhere; only the configuration changes |
| Scalability | Independent tasks run in parallel, from 3 to 3,000 samples |
| Executor | The component that launches tasks: `local`, `slurm`, `awsbatch`, … |
| Locale | Language/sorting settings (`LC_ALL`) that can silently change results |
| DAG | Directed acyclic graph: the processes and the channels connecting them |

**Commands used:** `LC_ALL=… command`, `sort`, `join`, `diff`, `locale`.

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="1.2"></div>
