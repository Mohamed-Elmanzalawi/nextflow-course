# Glossary & cheat sheet

New terms and commands are added as each module is written. The lesson where each one was introduced is in brackets.

## Terms

Workflow / pipeline *(1.1)*
:   An ordered set of analysis steps, where each step's output feeds the next.

Workflow manager *(1.1)*
:   Software that runs a workflow for you. It decides when and where each step runs, with which software, and how to handle failures and reruns.

Nextflow *(1.1)*
:   A workflow language built on Groovy, plus the engine that runs it. Pipelines are portable across laptops, HPC clusters and clouds.

DSL2 *(1.1)*
:   The current dialect of the Nextflow language. It is modular, with reusable processes, workflows and modules. DSL1 is obsolete.

Process *(1.1)*
:   The definition of one step in a pipeline, e.g. "run FastQC on a FASTQ file".

Task *(1.1)*
:   One run of a process on one set of inputs. Three FASTQ files going into one process make three tasks.

Channel *(1.1)*
:   A queue that carries data (files or values) between processes.

Operator *(1.1)*
:   A function that transforms channels, e.g. `collect()` gathers every item into one list.

Dataflow *(1.1)*
:   A programming model in which each step runs as soon as its inputs are available. Execution order follows from the data, not from the order the code is written in.

Directive *(1.1, preview)*
:   A setting inside a process that controls how its tasks run, e.g. `publishDir`, `cpus`, `memory`.

nf-core *(1.1)*
:   A community collection of peer-reviewed Nextflow pipelines, modules and standards.

Reproducibility *(1.2)*
:   Same inputs + same code + same environment → same results.

Portability *(1.2)*
:   The same pipeline runs on a laptop, a cluster or the cloud. Only the configuration changes.

Scalability *(1.2)*
:   Independent tasks run in parallel, so the same code handles 3 or 3,000 samples.

Executor *(1.2)*
:   The component that launches tasks: `local`, `slurm`, `awsbatch`, `google-batch`, … Set in the configuration.

DAG *(1.2)*
:   *Directed acyclic graph*: a pipeline's processes connected by channels, with no loops.

Locale *(1.2)*
:   Language and sorting settings (`LC_ALL`, `LANG`) that can silently change the results of tools like `sort` and `join`.

Exit code *(2.1)*
:   A number a program returns: `0` = success, anything else = failure. Nextflow judges every task **only** by this. 137 = killed (often memory); 143 = terminated (often a time limit).

pipefail *(2.1)*
:   A Bash option that makes a pipe fail if **any** command in it fails. **Not** on by default in Nextflow tasks (`bash -ue`). Enable it with `process.shell = ['/bin/bash', '-euo', 'pipefail']`.

Symlink / staging *(2.1)*
:   Nextflow places input files into each task folder as symbolic links (pointers), not copies.

Conda environment *(2.3)*
:   A folder of pinned software packages, from the `bioconda` and `conda-forge` channels.

Container / image / tag *(2.3)*
:   A running, isolated environment / the read-only template it starts from / the version label after `:`.

BioContainers *(2.3)*
:   A container image for every bioconda package, at `quay.io/biocontainers/…`.

Apptainer *(2.3)*
:   Rootless containers for HPC clusters (formerly Singularity). Runs Docker images.

Profile *(2.3)*
:   A named bundle of configuration settings, chosen with `-profile name`.

Language server *(2.4)*
:   A helper program behind the VS Code extension and `nextflow lint` that understands Nextflow code: errors as you type, hover docs, DAG preview.

Git commit / tag *(2.4)*
:   A saved snapshot of your files / a permanent name for one snapshot (e.g. a release).

## Commands

| Command | What it does | Lesson |
|---|---|---|
| `time <cmd>` | Measures how long a command takes | 1.1 |
| `chmod 000 file` / `chmod 644 file` | Removes / restores read permission (used to simulate a crash) | 1.1 |
| `LC_ALL=C command` | Run a command with byte-order sorting rules | 1.2 |
| `set -euo pipefail` | Stop on errors, unset variables, and failures anywhere in a pipe | 2.1 |
| `ln -s target link` / `readlink -f link` | Make / resolve a symlink | 2.1 |
| `sdk install java` | Install Java with SDKMAN | 2.2 |
| `nextflow info` | Show the Nextflow version and runtime | 2.2 |
| `nextflow run hello` | Run a pipeline from GitHub (`nextflow-io/hello`) | 2.2 |
| `nextflow self-update` | Update to the latest stable Nextflow | 2.2 |
| `NXF_VER=x.y.z nextflow …` | Use an exact Nextflow version | 2.2 |
| `nextflow log` | List previous runs in this folder | 2.2 |
| `nextflow info <pipeline>` / `nextflow view <pipeline>` | Where a downloaded pipeline lives / print its code | 2.2 |
| `docker run --rm --platform linux/amd64 image cmd` | Run a command in a container (amd64 on Apple Silicon) | 2.3 |
| `conda create -n name -c conda-forge -c bioconda tool=ver` | Create a pinned conda environment | 2.3 |
| `nextflow run main.nf -profile docker` | Run with a configuration profile | 2.3 |
| `nextflow config -flat -profile x .` | Print the resolved configuration | 2.3 |
| `nextflow lint main.nf` | Check Nextflow code for errors | 2.4 |
| `git init -b main` / `git add` / `git commit -m` / `git tag` | Version control basics | 2.4 |
| `git check-ignore -v path` | Show which `.gitignore` rule ignores a path | 2.4 |
