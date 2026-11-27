---
lesson: "2.3"
module: 2
level: 1
---

# Lesson 2.3: Software environments: Conda, Docker and Apptainer

!!! info "About this lesson"
    **You'll learn:**

    - why every pipeline step needs a **fixed software environment**;
    - how **Conda**, **Docker** and **Apptainer** each provide one;
    - how Nextflow switches between them with one setting;
    - what's special about your **Apple Silicon** Mac.

    **Why it matters:** in Lesson 1.2 you saw an environment setting silently change results. Real pipelines pin the **exact tool version** for every step. This lesson is the "how".

    **Time:** about 1.5 h · **Level:** Beginner · **Needs:** Docker Desktop running, conda, Nextflow (Lesson 2.2)

    **Docs:** [Containers](https://docs.seqera.io/nextflow/container) · [Conda](https://docs.seqera.io/nextflow/conda) · [BioContainers](https://biocontainers.pro/)

!!! flo "Flo says"
    Today you'll run **the same FastQC** three ways: from a container, from a conda environment, and from Nextflow switching between them with a single word. Same version every time, guaranteed.

---

## A. Concept

### The problem: "works on my machine"

Your pipeline might use FastQC 0.12.1, samtools 1.21 and Python 3.11, while your colleague's laptop has FastQC 0.11.9 and the cluster has samtools 1.9. The tools' behaviour and defaults differ, and so do the results. The fix is to **ship the software with the pipeline**, one environment per step.

!!! analogy "Real-life analogy: lunch boxes"
    - **Conda** is like a shopping list: every machine goes to the shop (the package channels) and buys the **same brands and sizes**, then cooks locally.
    - A **container** is a **sealed lunch box**: the food is already cooked and packed, OS bits included. Open it anywhere and it's identical.

### The three tools

| | **Conda** | **Docker** | **Apptainer** (formerly Singularity) |
|---|---|---|---|
| What you get | An environment folder with the packages installed | A **container** started from an **image** | A container started from a `.sif` image **file** |
| Where it's used | Laptops and clusters | Laptops, cloud | **HPC clusters** |
| Needs admin/root? | No | Needs the Docker daemon (Docker Desktop on Mac) | **No**, which is why clusters allow it |
| Reproducibility | Good if versions are pinned; it builds anew each time | Excellent: the image is byte-for-byte fixed | Excellent: same images as Docker |
| Bioinformatics source | `bioconda` + `conda-forge` channels | **BioContainers** (`quay.io/biocontainers/…`), Seqera Containers | The same Docker images, converted automatically |

A few words you'll keep meeting:

- **Image**: the packed, read-only template, e.g. `quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0`.
- **Container**: a running instance of an image.
- **Registry**: where images are stored (quay.io, Docker Hub, …).
- **Tag**: the part after `:`, which pins the version.

!!! funfact "Fun fact"
    Every bioconda package automatically gets a matching Docker image on **BioContainers**, with the same name and version in the tag. That's why `fastqc=0.12.1` in conda matches `quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0`: the `hdfd78af_0` part is the bioconda **build string**. [biocontainers.pro](https://biocontainers.pro/)

### Your Apple Silicon Mac: arm64 vs amd64

Your Mac's CPU is **arm64**. Most bioinformatics container images are built only for **amd64** (Intel/AMD), the architecture of almost every cluster. Docker Desktop can **emulate** amd64, which works but is slower. Docker warns you unless you ask for amd64 explicitly:

```text title="Real output (FastQC image on this Mac)"
WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
FastQC v0.12.1
```

Adding `--platform linux/amd64` removes the warning. For conda, many tools now have native **osx-arm64** builds (FastQC, samtools 1.25 and bwa 0.7.19 all do, checked for this lesson). For a tool that doesn't, you can install the Intel build to run under Rosetta: `CONDA_SUBDIR=osx-64 conda create …`.

### How Nextflow uses them

You declare **in the process** which software it needs. You enable **in the configuration** which system to use:

```groovy title="module02_environment/lesson03_containers/main.nf"
--8<-- "module02_environment/lesson03_containers/main.nf"
```

```groovy title="module02_environment/lesson03_containers/nextflow.config"
--8<-- "module02_environment/lesson03_containers/nextflow.config"
```

| Line | What it does |
|---|---|
| `container '…'` | The image to use **when containers are enabled** |
| `conda '…'` | The conda package(s) to use **when conda is enabled** |
| `profiles { … }` | Named bundles of settings you choose with `-profile` |
| `docker.enabled = true` | Run every process with a `container` inside Docker |
| `docker.runOptions = '--platform linux/amd64'` | Extra flags for `docker run`: here, the Apple Silicon fix |
| `conda.enabled = true` | Build/reuse a conda env from each process's `conda` line |

--8<-- "includes/anim/profile_switch.html"

The pipeline declares both, so the **same `main.nf`** runs anywhere: `-profile docker` on your Mac, `-profile apptainer` on your cluster, or `-profile conda` where containers aren't available.

---

## B. Demonstration

```bash title="Terminal"
cd "$COURSE"/module02_environment/lesson03_containers

# 1. A container, straight from Docker
docker run --rm --platform linux/amd64 quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0 fastqc --version

# 2. The same version from conda (a dedicated environment for this course)
conda create -y -n nf-fastqc -c conda-forge -c bioconda fastqc=0.12.1
conda run -n nf-fastqc fastqc --version

# 3. Nextflow, switching with one word
nextflow run main.nf -profile docker
nextflow run main.nf -profile conda
```

??? predict "Predict: what will each Nextflow run print, and which one is slower the first time?"
    Real output from the test setup (Nextflow 26.10.7):

    ```text title="Real output: -profile docker"
     N E X T F L O W   ~  version 26.10.7

    Launching `main.nf` [goofy_payne] revision: abdef03057

    executor >  local (1)
    [99/ff6630] FASTQC_VERSION | 1 of 1 ✔
    Inside the task: FastQC v0.12.1
    ```

    ```text title="Real output: -profile conda"
     N E X T F L O W   ~  version 26.10.7

    Launching `main.nf` [prickly_bell] revision: abdef03057

    executor >  local (1)
    [c2/82a89a] FASTQC_VERSION | 1 of 1 ✔
    Creating env using conda: bioconda::fastqc=0.12.1 [cache …/work/conda/env-49dea791c31ead673ed2e341e1c6d206]
    Inside the task: FastQC v0.12.1
    ```

    Same version, same result. The **conda** run took about **18 s** the first time, because Nextflow had to **build the environment** (it reuses it afterwards). The Docker image was already downloaded, so that run took only a few seconds.

---

## C. Walkthrough: what Nextflow actually ran

Nextflow writes the full command for every task into `.command.run` in the task's folder. With `-profile docker`, the real file contained a line starting:

```text title="From work/…/.command.run (real, shortened)"
docker run -i --cpu-shares 1024 -e "NXF_TASK_WORKDIR" -v /…/work:/…/work …
```

So **you** never type `docker run`. Nextflow builds the command, mounts the work folder into the container, and runs your `script:` inside it. With Apptainer on a cluster, it builds the equivalent `apptainer exec …` command.

!!! gotcha "Gotcha! Declaring isn't enabling"
    A `container` line in a process does **nothing** unless containers are enabled (`docker.enabled = true` or similar, usually via `-profile`). Without that, the task quietly uses whatever FastQC is on your `PATH`, or fails with `command not found`. "Forgot `-profile docker`" is one of the most common beginner errors.

!!! protip "Pro tip: pin exact tags, never `latest`"
    `fastqc:latest` can point to a different version next month. Always use a full tag like `0.12.1--hdfd78af_0`. nf-core modules do exactly this.

---

## D. Guided exercise (about 30 min)

```quiz
id: 2.3-ex-steps
type: steps
concept: software-environments
label: "Mission steps"
steps:
  - "Make sure **Docker Desktop** is running (whale icon in the menu bar)."
  - "Run the Docker command from section B, first **without** `--platform linux/amd64` and then **with** it. Compare the output."
  - "Create the `nf-fastqc` conda environment and check its FastQC version (section B, step 2)."
  - "Run `main.nf` with `-profile docker`, then with `-profile conda`."
  - "Run `main.nf` with **no profile at all**, and read what happens (you probably have no FastQC installed outside these environments)."
```

```quiz
id: 2.3-ex-a
type: single
concept: apple-silicon
question: "What did the Docker warning (without `--platform`) tell you?"
options:
  - text: "The image is broken and must be rebuilt."
  - text: "The image is built for **amd64** but your Mac is **arm64**, so Docker is emulating amd64."
    correct: true
  - text: "FastQC 0.12.1 is outdated."
explain: "It's only a warning: the tool still runs, under emulation. On an amd64 cluster the same image runs natively. Using `--platform linux/amd64` (via `docker.runOptions`) states this explicitly and silences the warning."
```

```quiz
id: 2.3-ex-b
type: single
concept: software-environments
question: "What happened when you ran `main.nf` with **no** `-profile`?"
options:
  - text: "Nextflow used Docker anyway, because the process has a `container` line."
  - text: "Nextflow ran `fastqc` from your normal `PATH`, so it failed with *command not found* if FastQC isn't installed there."
    correct: true
  - text: "Nextflow asked which environment to use."
explain: "Declaring a `container` or `conda` in a process doesn't **enable** it. The configuration must turn it on. Without a profile, the task runs on your plain system, which is exactly the irreproducible situation you want to avoid."
```

```quiz
id: 2.3-ex-c
type: multi
concept: software-environments
question: "Your SLURM cluster gives you **no root/admin rights** and doesn't run a Docker daemon. Which options can you use there? Tick all that apply."
options:
  - text: "Apptainer"
    correct: true
  - text: "Conda (Miniforge in your home folder)"
    correct: true
  - text: "Docker"
explain: "Apptainer was designed for multi-user HPC: no root, no daemon, and it runs the same Docker/BioContainers images. Conda installs into your home folder. Docker usually isn't available on shared clusters."
```

---

## E. Independent challenge: get ready for your cluster

Add an **`apptainer`** profile to `nextflow.config` in the lesson folder. It must enable Apptainer and turn on **automatic mounting** of host paths. Search the [Apptainer section of the config docs](https://docs.seqera.io/nextflow/reference/config#apptainer) for the right two settings.

You can't run Apptainer on a Mac, but `nextflow config` can still check your profile. The checker below also confirms everything from section D.

```quiz
id: 2.3-containers
type: check
concept: software-environments
label: "Challenge: auto-checked"
check: 2.3-containers
command: "bash check_containers.sh"
solution: includes/solutions/2.3/nextflow.config
hint: "The docker profile uses `docker.enabled`. The apptainer settings follow the same pattern: `apptainer.<setting> = …`. You can print the resolved settings with `nextflow config -flat -profile apptainer .`."
explain: |
  `apptainer.enabled = true` makes Nextflow run each process's `container` with Apptainer. Docker images are converted to `.sif` automatically.

  `apptainer.autoMounts = true` makes host paths (your data and work folders) visible inside the container.

  On your cluster you'll usually also set `apptainer.cacheDir`, so images are downloaded once and shared between runs. That's coming in Module 7.
```

---

## F. Knowledge check

```quiz
id: 2.3-q1
type: single
concept: software-environments
question: "What's the difference between a container **image** and a **container**?"
options:
  - text: "They're the same thing."
  - text: "The image is the packed, read-only template; a container is a running instance started from it."
    correct: true
  - text: "Images are for Docker; containers are for Apptainer."
explain: "Like a recipe card (image) and a dish being cooked from it (container). Many containers can run from one image at the same time, which is exactly what happens when Nextflow runs many tasks."
```

```quiz
id: 2.3-q2
type: single
concept: reproducibility-pillars
question: "Which container reference is best for reproducibility?"
options:
  - text: "`quay.io/biocontainers/fastqc`"
  - text: "`quay.io/biocontainers/fastqc:latest`"
  - text: "`quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0`"
    correct: true
explain: "Without a tag, Docker assumes `latest`, which can change at any time. A full version + build tag always points to the same software."
```

```quiz
id: 2.3-q3
type: open
concept: software-environments
question: "In your own words: why does Nextflow keep **which software** a process needs (in `main.nf`) separate from **how to provide it** (in the config/profile)?"
model: "So the **same pipeline** can run in different places. The process states *what* it needs (this FastQC version). The profile decides *how* to get it on this machine: Docker on a laptop, Apptainer on HPC, conda where containers aren't allowed. You change one word (`-profile`) instead of editing the pipeline. It's the same *what* vs *where* separation as executors in Lesson 1.2."
```

---

## G. Summary

| Term / command | Meaning |
|---|---|
| Conda environment | A folder of pinned packages, from `bioconda` + `conda-forge` |
| Image / container / tag | Template / running instance / version label |
| BioContainers | A container image for every bioconda package (`quay.io/biocontainers/…`) |
| Apptainer | Rootless containers for HPC; runs Docker images |
| arm64 vs amd64 | Your Mac vs most images and clusters; use `--platform linux/amd64` |
| `container '…'` / `conda '…'` | Declare software **in a process** |
| `docker.enabled` / `apptainer.enabled` / `conda.enabled` | **Enable** a system in the config |
| `-profile name` | Choose a named bundle of settings |
| `nextflow config -flat -profile x .` | Print the resolved configuration |

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="2.3"></div>
