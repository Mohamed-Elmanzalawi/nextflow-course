---
lesson: "3.1"
module: 3
level: 1
---

# Lesson 3.1: Anatomy of a Nextflow script

!!! info "About this lesson"
    **You'll learn:**

    - the two building blocks of every script: **processes** and the **workflow**;
    - what happens, step by step, when you type `nextflow run`;
    - how to read Nextflow's console display;
    - where your results really are (spoiler: inside `work/`).

    **Why it matters:** every pipeline you'll ever read, including nf-core's 100+ step pipelines, is built from these same two blocks. Once you can read a 13-line script, you can read any of them, one block at a time.

    **Time:** about 1 h · **Level:** Beginner · **Needs:** Nextflow 26.10 (Lesson 2.2)

    **Docs:** [Your first script](https://docs.seqera.io/nextflow/your-first-script) · [Processes](https://docs.seqera.io/nextflow/process) · [Workflows](https://docs.seqera.io/nextflow/workflow)

!!! flo "Flo says"
    In Lesson 2.2 you ran someone else's `hello` pipeline. Today you write your own, and then you open its hood. Every hand-written line has a job, and you'll see exactly which one.

---

## A. Concept

### Two blocks: *what* to do and *how it connects*

A Nextflow script has two kinds of building blocks:

| Block | Job | Python analogy |
|---|---|---|
| **`process`** | One step of the pipeline: which inputs it takes, which Bash commands it runs, which files it produces | A **function definition** (`def say_hello(): …`). Defining it runs nothing. |
| **`workflow`** | The wiring: which processes run, and what flows between them | The `if __name__ == "__main__":` part that **calls** the functions |

Here's the smallest useful script:

=== "Nextflow"

    ```groovy title="hello.nf"
    --8<-- "module03_first_pipeline/lesson01_anatomy/hello.nf"
    ```

=== "Python equivalent"

    ```python title="hello.py"
    --8<-- "module03_first_pipeline/lesson01_anatomy/hello.py"
    ```

    ```text title="Real output: python3 hello.py && cat py_work/hello.txt"
    py_work/hello.txt
    Hello from Python!
    ```

!!! note "Where the analogy stops"
    Python runs `say_hello()` in the current folder and writes wherever you tell it. Nextflow gives every task its **own** fresh folder in `work/`, runs the script there, and then **checks** that the promised `hello.txt` exists.

Read it like this:

1. `process SAY_HELLO { … }` **defines** a step called `SAY_HELLO`. Process names are written in CAPITALS by convention.
2. `output: path 'hello.txt'` is a **promise**: when the step finishes, a file called `hello.txt` will exist. Nextflow checks it.
3. `script:` holds a string between `"""` triple quotes. That string **is Bash**. Nextflow runs it exactly like a little `.sh` file.
4. `workflow { SAY_HELLO() }` **calls** the process. Without this call, nothing would run, just as defining a Python function doesn't run it.

!!! analogy "Real-life analogy: a recipe card and a kitchen order"
    A `process` is a **recipe card**: "to make hello.txt, do this". The `workflow` is the **order ticket**: "make one SAY_HELLO, please". The kitchen (Nextflow) only cooks what's ordered, and each order gets its own clean bench to work on.

### What `nextflow run` actually does

--8<-- "includes/anim/run_anatomy.html"

Two ideas from the animation will come back in every lesson:

- **Task:** one execution of a process. One call here means one task. In Lesson 3.2 one call creates many tasks.
- **Task folder:** every task runs in its own folder inside `work/`, named by a **hash** (a long hex code like `54/3b7873c4…`). The first 8 characters are what the console shows.

---

## B. Demonstration

Go to the lesson folder and run the script:

```bash title="Terminal"
cd "$COURSE"/module03_first_pipeline/lesson01_anatomy
nextflow run hello.nf
```

??? predict "Predict: what will the console show? Where will `hello.txt` end up?"
    Real output (Nextflow 26.10.7):

    ```text title="Real output"
     N E X T F L O W   ~  version 26.10.7

    Launching `hello.nf` [zen_marconi] revision: 5777a0f7e0

    executor >  local (1)
    [54/3b7873] SAY_HELLO | 1 of 1 ✔
    ```

    And `hello.txt` is **not** in your lesson folder! It's inside the task folder:

    ```bash title="Terminal"
    ls
    ```

    ```text title="Real output"
    check_greet.sh  greet.nf        hello.nf        hello_input.nf  work
    ```

### Reading the display, line by line

| Line | Meaning |
|---|---|
| `N E X T F L O W ~ version 26.10.7` | The banner, with the Nextflow version that ran. Note it down when you report a problem. |
| `` Launching `hello.nf` `` | The script being run. |
| `[zen_marconi]` | A random **run name** (an adjective plus a scientist). You can use it later with `nextflow log`. |
| `revision: 5777a0f7e0` | A fingerprint of the script's text. Change one character and it changes. |
| `executor > local (1)` | Tasks run on **this computer** (`local`), and 1 task was started. On your cluster this will say `slurm`. |
| `[54/3b7873]` | The start of the task's folder name: `work/54/3b7873…`. |
| `SAY_HELLO \| 1 of 1 ✔` | The process name, how many of its tasks have finished, and ✔ when all succeeded. |

While a run is going, the last lines are **live**: they count up (`0 of 3`, `1 of 3`, …) and are redrawn in place.

!!! gotcha "Gotcha! The display depends on your window width"
    In a **wide** terminal window (about 140 characters or more) the same line looks like this:

    ```text
    [54/3b7873] process > SAY_HELLO [100%] 1 of 1 ✔
    ```

    Same information, different layout. Don't be surprised when tutorials and screenshots look slightly different from your screen.

### Find the result

Use the hash from **your** console (yours will differ from `54/3b7873`). Tab completion fills in the rest of the folder name:

```bash title="Terminal"
ls -a work/54/3b7873*
cat work/54/3b7873*/hello.txt
cat work/54/3b7873*/.command.sh
```

```text title="Real output"
.               .command.begin  .command.log    .command.run    .exitcode
..              .command.err    .command.out    .command.sh     hello.txt

Hello from Nextflow!

#!/bin/bash -ue
echo 'Hello from Nextflow!' > hello.txt
```

The `script:` block became `.command.sh`, with `#!/bin/bash -ue` added on top (the `-u` and `-e` flags from Lesson 2.1). It ran inside this folder and wrote `hello.txt` there.

---

## C. Code walkthrough

### The hidden files in every task folder

| File | What it holds |
|---|---|
| `.command.sh` | **Your** script, exactly as Bash ran it. The first thing to read when a task misbehaves. |
| `.command.run` | Nextflow's **wrapper**: it sets up the folder, then runs `.command.sh`. On a cluster, this is what gets submitted to SLURM. |
| `.command.out` / `.command.err` | Everything the script printed to standard output / standard error. |
| `.exitcode` | The script's exit code. `0` means success (Lesson 2.1). |
| `.command.begin`, `.command.log` | Bookkeeping: when the task started, and the wrapper's own log. |

You'll use these files to debug failing tasks in Lesson 4.3.

### What else appeared in your folder

```bash title="Terminal"
ls -a
```

```text title="Real output"
.               .nextflow       check_greet.sh  hello.nf        work
..              .nextflow.log   greet.nf        hello_input.nf
```

| Item | What it is |
|---|---|
| `work/` | All task folders. It grows with every run. |
| `.nextflow.log` | A detailed log of the **last** run. Older ones are renamed `.nextflow.log.1`, `.2`, … |
| `.nextflow/` | Nextflow's memory of past runs: the history used by `nextflow log` and the cache used by `-resume` (Lesson 3.4). |

### A process with an input

`hello_input.nf` gives the process something to work on:

```groovy title="hello_input.nf"
--8<-- "module03_first_pipeline/lesson01_anatomy/hello_input.nf"
```

What's new:

- `input: val greeting` means each task receives **one value** and calls it `greeting`. (`val` is for values like strings and numbers; files use `path`, which you'll see in Lesson 3.2.)
- `"${greeting}.txt"` inserts the value into a string, like a Python f-string: `f"{greeting}.txt"`.
- `channel.of('Hello', 'Bonjour', 'Hola')` creates a **channel**, a queue of values. Giving a channel of 3 values to a process creates **3 tasks**. You'll study channels properly in Module 5.

```bash title="Terminal"
nextflow run hello_input.nf
```

```text title="Real output"
 N E X T F L O W   ~  version 26.10.7

Launching `hello_input.nf` [disturbed_ramanujan] revision: 786f2f9db5

executor >  local (3)
[31/e07fc2] SAY_HELLO (2) | 3 of 3 ✔
```

Three tasks, three folders. The display shows only the **latest** task's hash to save space. To see one line per task, turn off the live display with `-ansi-log false`:

```bash title="Terminal"
nextflow run hello_input.nf -ansi-log false
```

```text title="Real output"
N E X T F L O W  ~  version 26.10.7
Launching `hello_input.nf` [distraught_mestorf] - revision: 786f2f9db5
[ab/54ebe6] Submitted process > SAY_HELLO (3)
[9a/1b788d] Submitted process > SAY_HELLO (2)
[d1/cff222] Submitted process > SAY_HELLO (1)
```

Notice the order: task 3 was submitted first. The three tasks are independent, so Nextflow starts them in whatever order it gets to them.

!!! protip "Pro tip: `-ansi-log false` on clusters"
    The live display redraws lines in place, which turns into a mess in a SLURM log file. In batch jobs, always add `-ansi-log false` (or set `NXF_ANSI_LOG=false`).

!!! funfact "Fun fact"
    Run the same script twice and you get **new** task folders every time: Nextflow doesn't reuse anything unless you ask it to with `-resume`. After the two runs above, `ls work/*/*/*.txt` lists **two** copies of every greeting:

    ```text title="Real output"
    work/31/e07fc249ba2377732ae250b3c99e89/Bonjour.txt
    work/54/3b7873c4a830daade0fbdf64c609d4/hello.txt
    work/76/8a2209a9bb4e26e46c616c831ef6ca/Hola.txt
    work/9a/1b788d6125009cbc3c00c565c6179b/Bonjour.txt
    work/ab/54ebe6a29c11ade143e13f82ddda88/Hola.txt
    work/d1/cff22264616b010f2a952e69e07e8a/Hello.txt
    work/d6/34545c226b2c625744a1b32c83717e/Hello.txt
    ```

    Lesson 3.4 turns that waste into a superpower.

---

## D. Guided exercise (about 20 min)

```quiz
id: 3.1-ex-steps
type: steps
concept: running-a-script
label: "Mission steps"
steps:
  - "Run `hello.nf` and find `hello.txt` inside `work/` using the hash on your console."
  - "Open that task's `.command.sh` and `.exitcode`."
  - "Run `hello.nf` a **second** time. Compare the hash with the first run, and count the folders: `ls work/*/`."
  - "Run `hello_input.nf`, then again with `-ansi-log false`."
  - "Look at the end of `.nextflow.log` with `tail .nextflow.log`."
```

```quiz
id: 3.1-ex-a
type: single
concept: task-folders
question: "You ran `hello.nf` twice. What happened to the task folders?"
options:
  - text: "The second run overwrote the first folder."
  - text: "The second run created a **new** folder with a different hash; both folders are still in `work/`."
    correct: true
  - text: "The second run reused the first folder because nothing changed."
explain: "Without `-resume`, every run starts from scratch and creates new task folders. Nothing is deleted, so `work/` keeps growing. Reusing finished work is exactly what `-resume` adds (Lesson 3.4)."
```

```quiz
id: 3.1-ex-b
type: number
concept: tasks
question: "How many task folders does **one** run of `hello_input.nf` create?"
answer: 3
tolerance: 0
unit: folders
explain: "One task per item in the channel: `'Hello'`, `'Bonjour'` and `'Hola'`. Each task gets its own folder."
```

```quiz
id: 3.1-ex-c
type: multi
concept: task-folders
question: "Which files did you find in a task folder? Tick all that apply."
options:
  - text: "`.command.sh`"
    correct: true
  - text: "`.exitcode`"
    correct: true
  - text: "`hello.txt` (the output)"
    correct: true
  - text: "`hello.nf` (a copy of the script)"
  - text: "`.nextflow.log`"
explain: "The task folder holds the generated Bash script, the wrapper, the captured output streams, the exit code and the files the task produced. The pipeline script and the run log stay in your launch folder."
```

---

## E. Independent challenge

Complete `greet.nf` in the lesson folder. It has `TODO` comments to fill in. When it works:

- a process **`GREET`** takes **one name** as input;
- each task writes a file **`greeting_<name>.txt`** containing exactly `Hello, <name>!` (for example `Hello, Ada!`);
- the workflow greets **Ada**, **Rosalind** and **Barbara**.

```groovy title="greet.nf (starter)"
--8<-- "module03_first_pipeline/lesson01_anatomy/greet.nf"
```

```quiz
id: 3.1-challenge
type: check
concept: processes
label: "Challenge: auto-checked"
check: 3.1-challenge
command: "bash check_greet.sh"
solution: includes/solutions/3.1/greet.nf
hint: "Start from `hello_input.nf`: it already has a `val` input and a channel. Change the names, the output file name and the `echo` text. Use single quotes around the echo text, so Bash doesn't treat the `!` specially."
explain: "The checker runs your script on a fresh copy, counts the `GREET` tasks in Nextflow's trace file, and reads every greeting file."
```

---

## F. Knowledge check

```quiz
id: 3.1-q1
type: single
concept: processes
question: "You define a process but never call it in the `workflow` block. What happens when you run the script?"
options:
  - text: "It runs once anyway."
  - text: "Nothing runs for that process; defining it is like defining a Python function you never call."
    correct: true
  - text: "Nextflow stops with an error."
explain: "A process definition is a recipe. Only the workflow's calls create tasks."
```

```quiz
id: 3.1-q2
type: single
concept: task-folders
question: "On the console you see `[4e/51c03b] SUMMARISE | 1 of 1 ✔`. Where do you look for that task's files?"
options:
  - text: "In `results/4e51c03b/`"
  - text: "In the folder `work/4e/51c03b…` (the rest of the name is longer)"
    correct: true
  - text: "In `.nextflow/4e/51c03b`"
explain: "The bracket shows the first characters of the task folder's path inside `work/`. Use `ls work/4e/51c03b*` and let the shell complete it."
```

```quiz
id: 3.1-q3
type: open
concept: processes
question: "In your own words: what does the `output:` block of a process promise, and what does Nextflow do if the promise isn't kept?"
model: "It declares which files (or values) the task will produce. After the script finishes, Nextflow checks that they exist. If a declared output is missing, the task **fails** with a 'Missing output file' error, even if the script's exit code was 0. That's how silent failures get caught."
explain: "Exit code 0 and all declared outputs present: both must be true for a ✔."
```

```quiz
id: 3.1-q4
type: single
concept: running-a-script
question: "Why should you add `-ansi-log false` when running Nextflow inside a SLURM batch job?"
options:
  - text: "It makes the pipeline run faster."
  - text: "The live display redraws lines in place, which becomes unreadable in a log file; plain mode prints one line per task."
    correct: true
  - text: "SLURM can't run Nextflow without it."
explain: "It only changes how progress is printed, not what runs."
```

---

## G. Summary

| Concept | Remember |
|---|---|
| `process` | Defines one step: inputs, outputs, and a Bash `script:` |
| `workflow` | Calls processes; nothing runs unless it's called here |
| Task | One execution of a process; one channel item → one task |
| Task folder | `work/xx/yyyyyy…`, named by a hash; holds `.command.sh`, `.exitcode` and the outputs |
| ✔ | Exit code 0 **and** every declared output exists |

| Command | Does |
|---|---|
| `nextflow run hello.nf` | Run a script |
| `nextflow run hello.nf -ansi-log false` | One plain line per task (logs, clusters) |
| `ls work/54/3b7873*` | Open a task folder from the console's hash |
| `tail .nextflow.log` | The detailed log of the last run |

Next: in **Lesson 3.2** you chain two processes into a real (tiny) pipeline, and finally run the Nextflow script you previewed in Lesson 1.1.

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="3.1"></div>
