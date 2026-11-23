---
lesson: "2.2"
module: 2
level: 1
---

# Lesson 2.2: Install Java and Nextflow

!!! info "About this lesson"
    **You'll learn:**

    - how to install **Java** (with SDKMAN) and **Nextflow** on your Mac;
    - how to check that the install works;
    - how to run your first real pipeline;
    - how to keep Nextflow up to date or pin an exact version.

    **Why it matters:** from Module 3 on, every lesson runs real Nextflow code. A clean install now saves hours of confusing errors later.

    **Time:** about 45 min · **Level:** Beginner · **Needs:** internet access

    **Docs:** [Installation](https://docs.seqera.io/nextflow/install) · [Updating Nextflow](https://docs.seqera.io/nextflow/updating-nextflow) · [Environment variables](https://docs.seqera.io/nextflow/reference/env-vars)

!!! flo "Flo says"
    Big day: by the end of this lesson, **a real Nextflow pipeline will run on your Mac**. One small checker run will confirm it, and this page will tick itself off. 🎉

---

## A. Concept

### What gets installed, and why

| Piece | What it is | Why you need it |
|---|---|---|
| **Java** | The runtime that Nextflow itself runs on (the JVM) | Nextflow is written in Groovy/Java. It needs **Java 17 or later, up to 26**. |
| **SDKMAN** | A small tool that installs and switches Java versions | The method recommended in the official docs. Easy upgrades, no admin rights needed. |
| **Nextflow** | One small launcher file called `nextflow` | On first run it downloads the rest of itself into `~/.nextflow`. |

!!! gotcha "Gotcha! The Mac's fake `java`"
    macOS ships a placeholder at `/usr/bin/java`. Running it just prints *"Unable to locate a Java Runtime"*. Your Mac has this placeholder right now, so `which java` finding something doesn't mean Java is installed. `java -version` must print a real version.

### Where the files go

```text
~/.sdkman/            ← SDKMAN and the Java versions it installs
~/.local/bin/nextflow ← the Nextflow launcher (you put it here)
~/.nextflow/          ← Nextflow's own files, downloaded on first run
```

Everything lives in your home folder, so you don't need `sudo`. You'll do the same on your SLURM cluster later, where you don't have admin rights.

---

## B. Demonstration: the install

!!! note "Where these commands come from"
    The commands below follow the official [installation page](https://docs.seqera.io/nextflow/install). The version numbers shown are what was current when this lesson was written (Nextflow **26.10.7**, SDKMAN's default Java **25**).

### Step 1: Install SDKMAN, then Java

```bash title="Terminal"
curl -s https://get.sdkman.io | bash
```

**Open a new terminal window** so SDKMAN loads, then:

```bash title="Terminal"
sdk install java
java -version
```

`sdk install java` installs SDKMAN's default, the latest long-term-support (LTS) **Temurin** build. `java -version` should now print a real version (17 or higher), not the placeholder message.

### Step 2: Install Nextflow

```bash title="Terminal"
cd ~
curl -s https://get.nextflow.io | bash
chmod +x nextflow
mkdir -p $HOME/.local/bin/
mv nextflow $HOME/.local/bin/
```

Make sure `~/.local/bin` is on your `PATH`. Your shell is **zsh**, so check, and add it to `~/.zshrc` if it's missing:

```bash title="Terminal"
echo "$PATH" | tr ':' '\n' | grep -q "$HOME/.local/bin" && echo "already on PATH" \
  || echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc
```

**Open a new terminal window again**, then continue.

### Step 3: Check it

```bash title="Terminal"
nextflow info
```

```text title="Real output (from the test install for this course)"
  Version: 26.10.7 build 15252
  Created: 20-11-2026 17:50 UTC (21-11-2026 02:50 JDT)
  System: Mac OS X 15.8.1
  Runtime: Groovy 4.0.33 on OpenJDK 64-Bit Server VM 21.0.13.1+2-LTS
  Encoding: UTF-8 (UTF-8)
```

Your `Runtime` line will show your own Java version (probably 25).

### Step 4: Run your first real pipeline

```bash title="Terminal"
mkdir -p ~/nf-scratch && cd ~/nf-scratch
nextflow run hello
```

??? predict "Predict: `hello` greets the world in four languages. In what order?"
    Real output from the test install:

    ```text title="Real output"
    Pulling nextflow-io/hello ...
     downloaded from https://github.com/nextflow-io/hello.git
    [PROCESS 8f/870f47] sayHello (1)
    [PROCESS ab/886ede] sayHello (2)
    [PROCESS e0/1d4b8a] sayHello (4)
    [PROCESS 8e/804478] sayHello (3)
    Ciao world!
    Hello world!
    Hola world!
    Bonjour world!

    [SUCCESS] completed=4 failed=0 cached=0
    ```

    The order **changes from run to run**: the four tasks run in parallel and print as they finish (remember Lesson 1.2!). In your terminal you'll also see a live, updating progress display instead of these plain lines.

---

## C. Walkthrough: what just happened?

| You typed | What Nextflow did |
|---|---|
| `nextflow run hello` | Looked for a pipeline called `hello`. Not a local file, so it treated it as **`nextflow-io/hello` on GitHub** and downloaded it into `~/.nextflow/assets/`. |
| | Read the pipeline: one process, `sayHello`, fed by a channel of four greetings. |
| | Created **4 tasks**, one per greeting, each in its own `work/xx/yyyy…` folder (the `8f/870f47` codes are the start of those folder names). |
| | Ran them **in parallel**, collected the output, and reported `completed=4`. |

Have a look at what it left behind:

```bash title="Terminal"
ls -a ~/nf-scratch            # work/  .nextflow/  .nextflow.log
ls ~/nf-scratch/work/*/*      # one folder per task
```

You'll explore `work/` properly in Lesson 3.4.

!!! protip "Pro tip: control your Nextflow version"
    - **Update** to the latest stable release: `nextflow self-update`
    - **Run one command with an exact version**, for reproducibility: `NXF_VER=26.10.7 nextflow run …`. Nextflow downloads that version if needed.

    Record the Nextflow version in your methods section, just like any other tool version.

!!! funfact "Fun fact"
    You can run **any** public GitHub pipeline by name, like `nextflow run nf-core/rnaseq`. That's how most people run nf-core pipelines. You'll do it in Module 12.

### Other ways to install (and why we didn't)

| Method | Verdict |
|---|---|
| `conda create -n nf-env bioconda::nextflow` | Works, but the official docs warn it "may lead to outdated versions, dependency conflicts, and Java compatibility issues". |
| Homebrew | Not covered by the official install guide. Stick with the documented method. |

---

## D. Guided exercise: install and verify (about 30 min)

```quiz
id: 2.2-ex-steps
type: steps
concept: installation
label: "Mission steps"
steps:
  - "Install SDKMAN and Java (Step 1). `java -version` prints a real version ≥ 17."
  - "Install Nextflow into `~/.local/bin` and make sure it's on your `PATH` (Step 2)."
  - "`nextflow info` works in a **new** terminal window (Step 3)."
  - "`nextflow run hello` completes 4 tasks (Step 4)."
```

Now let the checker confirm everything. It records your Java and Nextflow versions on your [progress page](../../progress.md):

```quiz
id: 2.2-install
type: check
concept: installation
label: "Install check: auto-checked"
check: 2.2-install
command: "bash check_install.sh"
hint: "Run it from `~/Desktop/Projects/learning_nextflow/module02_environment/lesson02_install`. If 'Nextflow on your PATH' fails, open a **new** terminal window first: PATH changes only apply to new shells."
explain: "All four checks green means your Mac is ready for every lesson up to Module 10."
```

??? tip "Troubleshooting"
    | Symptom | Fix |
    |---|---|
    | `Unable to locate a Java Runtime` | You're hitting the Mac placeholder. Open a new terminal (so SDKMAN loads), then `sdk current java`. |
    | `sdk: command not found` | Open a new terminal, or run `source "$HOME/.sdkman/bin/sdkman-init.sh"`. |
    | `nextflow: command not found` | `~/.local/bin` isn't on your `PATH` yet. Open a new terminal, or check `~/.zshrc`. |
    | `hello` can't download | Check your internet or proxy settings. GitHub must be reachable. |

---

## E. Independent challenge: explore a pipeline you didn't write

Using only `nextflow` commands and what's on your disk:

1. Find out **where** Nextflow stored the downloaded `hello` pipeline, and read its `main.nf`. Look through `nextflow help` for a command that shows **info** about a project and one that lets you **view** its code.
2. Run `hello` again **with your version pinned explicitly** using `NXF_VER`.
3. Run `nextflow log` in `~/nf-scratch` and work out what it shows.

```quiz
id: 2.2-ch-a
type: single
concept: running-remote-pipelines
question: "Where did Nextflow store the downloaded `nextflow-io/hello` pipeline?"
hint: "Try `nextflow info hello`. Look for the **local path** line."
options:
  - text: "`~/nf-scratch/hello/`"
  - text: "Inside `~/.nextflow/assets/`, in Nextflow 26.10 under `~/.nextflow/assets/.repos/nextflow-io/hello/`"
    correct: true
  - text: "`/usr/local/share/nextflow/`"
  - text: "Nowhere; it streams the code from GitHub every time."
explain: |
  Remote pipelines are cached under `~/.nextflow/assets/`. Nextflow 26.10 keeps a Git copy there plus one checked-out folder per revision (`…/clones/<commit>/`). Older versions and older tutorials use the simpler `~/.nextflow/assets/nextflow-io/hello/`.

  You rarely need the path itself:

  - `nextflow info hello` shows the location and the available **revisions**;
  - `nextflow view hello` prints `main.nf`;
  - `nextflow list` lists every downloaded pipeline;
  - `nextflow pull nextflow-io/hello` updates one.

  Bonus: `hello` has tagged releases (`v1.1`–`v1.3`). `nextflow run hello -r v1.3` runs exactly that release, which is pinning the **code** version (Lesson 1.2's reproducibility, again).
```

```quiz
id: 2.2-ch-b
type: open
concept: running-remote-pipelines
question: "Look at `main.nf` of `hello`. In 2–3 sentences: what is its process called, what feeds it, and why did you get **4** tasks?"
model: "The process is `sayHello`. A **channel** of four greetings (Bonjour, Ciao, Hello, Hola) feeds it, so each greeting becomes one **task**: 4 items → 4 tasks, run in parallel. Each task prints its greeting followed by \"world!\"."
```

```quiz
id: 2.2-ch-c
type: single
concept: provenance
question: "What does `nextflow log` show?"
options:
  - text: "The contents of `.nextflow.log`"
  - text: "A table of **previous runs** in this folder: when they ran, how long they took, their auto-generated run name, status and command"
    correct: true
  - text: "Your shell history"
explain: "`nextflow log` lists the runs recorded in this folder's `.nextflow/` history. Each run gets a funny random name (like `tiny_curie`). You'll use it with `-resume` and for provenance in Module 8."
```

---

## F. Knowledge check

```quiz
id: 2.2-q1
type: single
concept: installation
question: "Which Java versions does current Nextflow support?"
options:
  - text: "Java 8 or later"
  - text: "Java 11 only"
  - text: "Java 17 or later, up to 26"
    correct: true
  - text: "Any version; Nextflow bundles Java"
explain: "From the official install page: \"Java 17 (or later, up to 26)\"."
```

```quiz
id: 2.2-q2
type: single
concept: reproducibility-pillars
question: "You're writing the methods section of a paper. How do you make sure a reviewer can rerun with **exactly** your Nextflow version?"
options:
  - text: "Tell them to run `nextflow self-update` first."
  - text: "Report the version and tell them to run with `NXF_VER=<version> nextflow run …`"
    correct: true
  - text: "Nextflow versions never change behaviour, so it doesn't matter."
explain: "`self-update` gives the **latest** version, not *yours*. `NXF_VER` pins an exact one. Treat Nextflow like any other tool version you report."
```

```quiz
id: 2.2-q3
type: open
concept: installation
question: "You'll install Nextflow on your SLURM cluster later. Why is the home-folder method (SDKMAN + `~/.local/bin`) a good fit there?"
model: "On a cluster you usually have **no admin (sudo) rights**. SDKMAN and the Nextflow launcher install entirely inside your **home folder**, so you control your own Java and Nextflow versions without asking the admins, and you can pin or update them yourself."
```

---

## G. Summary

| Command | What it does |
|---|---|
| <code>curl -s https://get.sdkman.io &#124; bash</code> | Install SDKMAN |
| `sdk install java` | Install the default Java (latest LTS Temurin) |
| <code>curl -s https://get.nextflow.io &#124; bash</code> | Download the Nextflow launcher |
| `nextflow info` | Show the version and runtime |
| `nextflow run hello` | Run the `nextflow-io/hello` pipeline from GitHub |
| `nextflow self-update` | Update to the latest stable release |
| `NXF_VER=x.y.z nextflow …` | Use an exact Nextflow version |
| `nextflow log` | List previous runs in this folder |

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="2.2"></div>
