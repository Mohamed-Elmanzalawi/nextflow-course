<div class="nb-hero" markdown>
<img class="nb-hero__flo" src="assets/flo/flo-wave.svg" alt="Flo, a cartoon lab flask wearing goggles, waving hello">
<div class="nb-hero__text" markdown>

# Learning Nextflow

**Hi, I'm Flo!** I'll carry your data through every pipeline in this notebook.

Together we'll go from **zero Nextflow** to **writing, running, debugging and maintaining real bioinformatics pipelines**, including nf-core ones, on your laptop and on your SLURM cluster.

</div>
</div>

The course is built on two sources, checked against the [official Nextflow documentation](https://docs.seqera.io/nextflow/):

- [EMBL-EBI: Introduction to Nextflow](https://www.ebi.ac.uk/training/online/courses/nextflow/introduction-to-nextflow/)
- [Nextflow Training](https://training.nextflow.io/latest/)

<div class="grid cards" markdown>

-   :material-play-circle:{ .lg .middle } **Start here**

    ---

    New to the course? Begin with the first lesson.

    [:octicons-arrow-right-24: Lesson 1.1: What is Nextflow?](level1/module01/lesson01.md)

-   :material-chart-timeline-variant:{ .lg .middle } **Your progress**

    ---

    Lessons completed, exercises done, and concepts to review.

    [:octicons-arrow-right-24: Progress record](progress.md)

-   :material-book-alphabet:{ .lg .middle } **Glossary & cheat sheet**

    ---

    Every term and command so far, in one place.

    [:octicons-arrow-right-24: Glossary](glossary.md)

-   :material-cog:{ .lg .middle } **Running this site**

    ---

    How to open the site, and where the exercise files live.

    [:octicons-arrow-right-24: Setup](setup.md)

</div>

## How this course works

Each lesson page has the same eight parts:

| Part | What happens |
|---|---|
| **A. Concept** | A plain-language explanation of the idea |
| **B. Demonstration** | A working example you run on your own machine |
| **C. Code walkthrough** | Every important line explained. Click the :material-plus-circle: markers in the code. |
| **D. Guided exercise** | A task with fold-out hints if you get stuck |
| **E. Independent challenge** | A harder task. No solution until you've tried it. |
| **F. Knowledge check** | 3–5 questions |
| **G. Summary** | Key concepts and commands |
| **H. Progress** | Where you are in the course |

!!! abstract "How you learn here: read → do → check → see progress"
    1. **Read** the lesson and run the demo in your terminal.
    2. **Do** the exercises. You answer every question right on the page:
        - multiple-choice and number questions are graded instantly;
        - for "in your own words" questions, you compare with a model answer and rate yourself.
    3. **Check** your hands-on work by running the lesson's checker script (`bash check_….sh`). The page updates by itself.
    4. **See your progress** on the [progress page](progress.md). Everything is tracked automatically, including the concepts you should review.

    Everything saves as you go. No need to send anything anywhere.

### A field guide to the boxes in this notebook

!!! flo "Flo says"
    Friendly framing: what we're about to do and why it's worth it.

!!! analogy "Real-life analogy"
    A new idea compared with something everyday, usually a kitchen. Nextflow is surprisingly like a busy restaurant.

??? predict "Predict the output"
    Make a guess **before** you run something, then click to compare with the real output. Guessing first makes the lesson stick.

!!! gotcha "Gotcha!"
    A trap that catches almost every beginner, and how to avoid it.

!!! protip "Pro tip"
    What experienced pipeline developers do.

!!! funfact "Fun fact"
    A bit of history or trivia. Every fact has a source.

Code blocks are labelled by **where the code goes**:

- `Terminal` means a shell command to run;
- `main.nf` or `nextflow.config` means text that goes inside a file.

## Course roadmap

=== "Level 1 · Beginner (~25 h)"

    **Goal:** understand the core ideas and run simple pipelines on your own.

    | Module | Lessons |
    |---|---|
    | **M1 Introduction** | 1.1 What is Nextflow? · 1.2 Reproducibility, portability, scalability and the dataflow model |
    | **M2 Environment** | 2.1 Bash refresher (only the parts Nextflow relies on) · 2.2 Install Java and Nextflow · 2.3 Conda, Docker, Apptainer, plus Apple Silicon caveats · 2.4 VS Code extension and Git |
    | **M3 First pipeline** | 3.1 Anatomy of a script · 3.2 Processes and workflows (DSL2) · 3.3 Inputs, outputs, `params`, publishing · 3.4 `work/` and `-resume` |
    | **M4 Processes in depth** | 4.1 Process blocks · 4.2 Directives · 4.3 Task isolation and exit codes · 4.4 `path` vs `val`, globs, `emit`, optional outputs |
    | **M5 Channels & dataflow** | 5.1 Queue vs value channels · 5.2 Channel factories and samplesheets · 5.3 Core operators · 5.4 Tuples and meta maps |

    :material-trophy: **Capstone 1:** FastQC on paired-end samples read from a samplesheet, then a MultiQC report.

=== "Level 2 · Intermediate (~32 h)"

    **Goal:** build modular DSL2 pipelines, configure where they run, and debug them.

    | Module | Lessons |
    |---|---|
    | **M6 Workflows & modules** | 6.1 `take` / `main` / `emit` · 6.2 Modules and `include` · 6.3 Subworkflows · 6.4 Workflow outputs vs `publishDir` |
    | **M7 Configuration & execution** | 7.1 `nextflow.config` and precedence · 7.2 Profiles, `withName` / `withLabel` · 7.3 Containers and Conda · 7.4 **SLURM** executor · 7.5 Reports and traces |
    | **M8 Debugging** | 8.1 Logs · 8.2 Inspecting failed tasks · 8.3 Caching and resume · 8.4 Common errors |
    | **M9 Best practices** | 9.1 Git and project layout · 9.2 Pinning versions · 9.3 Stub runs and nf-test · 9.4 Docs and nf-core standards |
    | **M10 Bioinformatics blocks** | FastQC → fastp · BWA/Bowtie2 · SAMtools · variant calling · RNA-seq with Salmon |

    :material-trophy: **Capstone 2:** a modular pipeline running FASTQ → QC → trim → align → BAM stats → variants → MultiQC, with profiles and containers.

=== "Level 3 · Advanced (~35 h)"

    **Goal:** production-quality pipelines, HPC tuning, nf-core.

    | Module | Lessons |
    |---|---|
    | **M11 Full pipeline from scratch** | Scaffold · samplesheet validation (nf-schema) · channel design · error handling and retries · nf-test · documentation · GitHub and CI |
    | **M12 Advanced Nextflow** | Advanced operators · dynamic directives · plugins and advanced config · typed syntax · HPC optimisation · cloud overview · nf-core in depth |

    :material-trophy: **Capstone 3:** your own research pipeline in nf-core style, run on your SLURM cluster.

## Learning outcomes

By the end you will be able to:

1. Explain how Nextflow works.
2. Read and write DSL2 scripts.
3. Create processes and connect them with channels and operators.
4. Build modular workflows.
5. Run pipelines locally and on SLURM.
6. Use Docker, Conda and Apptainer.
7. Debug and optimise pipelines.
8. Build reproducible workflows.
9. Read, change and develop nf-core pipelines.
10. Maintain your own pipeline independently.

!!! tip "Prerequisites"
    You already have what you need.

    - No Groovy is needed beforehand; the lessons teach the small amount Nextflow uses.
    - A Git refresher and Docker basics come in Module 2.
