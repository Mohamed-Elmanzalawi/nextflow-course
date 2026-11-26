---
lesson: "4.2"
module: 4
level: 1
---

# Lesson 4.2: Directives: resources, labels and retries

!!! info "About this lesson"
    **You'll learn:**

    - how to request **CPUs, memory and time** for each task;
    - how `tag` makes the console and the logs readable;
    - how `errorStrategy` and `maxRetries` handle failures;
    - how a **closure** like `{ 1.GB * task.attempt }` asks for more memory on every retry.

    **Why it matters:** on your SLURM cluster these directives become `sbatch` resource requests. Ask for too little and jobs die; ask for too much and they wait in the queue. Retries with growing memory let a pipeline fix the "out of memory" kills by itself.

    **Time:** about 1.25 h · **Level:** Beginner · **Needs:** Lesson 4.1

    **Docs:** [Process directives](https://docs.seqera.io/nextflow/reference/process) · [Dynamic directives](https://docs.seqera.io/nextflow/process#dynamic-directives) · [`errorStrategy`](https://docs.seqera.io/nextflow/reference/process/directives/error-strategy)

!!! flo "Flo says"
    Directives are the lines at the top of a process. They don't change *what* a task does, only *how* it runs: with how much, under which name, and what happens when it fails.

---

## A. Concept

### Directives

```groovy title="directives.nf"
--8<-- "module04_processes/lesson02_directives/directives.nf"
```

| Directive | Meaning | On SLURM it becomes… |
|---|---|---|
| `cpus 4` | CPUs for each task; read it in the script as `${task.cpus}` | `#SBATCH -c 4` |
| `memory 8.GB` | Memory for each task | `#SBATCH --mem 8192M` |
| `time '2h'` | Maximum run time; longer tasks are killed | `#SBATCH -t 02:00:00` |
| `tag "${sample}"` | A label shown on the console and in the logs | part of the job name: `#SBATCH -J nf-ALIGN_(s1)` |
| `errorStrategy 'retry'` | What to do when a task fails | (Nextflow decides) |
| `maxRetries 2` | How many times a failed task may be retried | |

Units are written like `8.GB`, `500.MB` or `'2h'`, `'30m'`. The SLURM column comes from a real `.command.run` that Nextflow 26.10 generated for a process called `ALIGN` with `-process.executor slurm`.

!!! info "Directives are per process, and in the config too"
    Writing resources inside each process is fine for learning. Real pipelines usually set them in `nextflow.config` instead, so they can differ between your laptop and the cluster. You'll do that in Module 7 (`withName`, `withLabel`).

### Dynamic directives: closures

`memory { 1.GB * task.attempt }` has **curly braces**: that makes it a **closure**, a small piece of code that Nextflow runs again **for every attempt** of every task. `task.attempt` is 1 the first time, 2 on the first retry, and so on.

Python analogy: a closure is a `lambda`. `memory 1.GB` is a fixed value; `memory { 1.GB * task.attempt }` is like `memory = lambda task: 1 * GB * task.attempt`, called each time.

--8<-- "includes/anim/retry_memory.html"

### Error strategies

| `errorStrategy` | When a task fails… |
|---|---|
| `'terminate'` (default) | Stop the whole run at once |
| `'finish'` | Start nothing new, let running tasks finish, then stop |
| `'ignore'` | Forget that task and carry on (its outputs are missing downstream!) |
| `'retry'` | Run the task again, up to `maxRetries` times |

The error strategy can also be a closure, so it can depend on **why** the task failed:

```groovy
errorStrategy { task.exitStatus == 137 ? 'retry' : 'terminate' }
```

Exit status 137 = 128 + 9: the task was killed with `SIGKILL`, which is what SLURM and the Linux out-of-memory killer do (Lesson 2.1). Retrying makes sense for that. A corrupt input file will fail every time, so retrying it only wastes time.

---

## B. Demonstration

```bash title="Terminal"
cd ~/Desktop/Projects/learning_nextflow/module04_processes/lesson02_directives
nextflow run directives.nf
```

??? predict "Predict: each task fails on its first attempt. What will the console show?"
    Real output:

    ```text title="Real output"
     N E X T F L O W   ~  version 26.10.7

    Launching `directives.nf` [irreverent_hypatia] revision: 13e65b6a98

    executor >  local (4)
    [45/5d3e20] FLAKY (s2) | 2 of 2, retries: 2 ✔
    [46/5197e1] NOTE: Process `FLAKY (s2)` terminated with an error exit status (137) -- Execution is retried (1)
    [ce/0e6097] NOTE: Process `FLAKY (s1)` terminated with an error exit status (137) -- Execution is retried (1)
    ```

    Four tasks ran (`local (4)`): two failed first attempts and two successful retries. Thanks to `tag`, the console says `FLAKY (s2)` instead of `FLAKY (1)`.

Ask Nextflow what happened to every attempt:

```bash title="Terminal"
nextflow log last -f name,tag,attempt,cpus,memory,status,exit
```

```text title="Real output"
FLAKY (s2)      s2      1       1       1 GB    FAILED  137
FLAKY (s1)      s1      1       1       1 GB    FAILED  137
FLAKY (s2)      s2      2       1       2 GB    COMPLETED       0
FLAKY (s1)      s1      2       1       2 GB    COMPLETED       0
```

(`last` means the most recent run.) The memory **doubled** on attempt 2, as the closure said. The successful task printed:

```text title=".command.out of the successful s2 task (real)"
attempt 2: 1 CPU, 2 GB
```

---

## C. Code walkthrough

### `task.*` inside the script

```text title=".command.sh of that task (real)"
#!/bin/bash -ue
echo "attempt 2: 1 CPU, 2 GB"
if [ 2 -lt 2 ]; then
    echo "pretend we ran out of memory" >&2
    exit 137
fi
echo done > s2.txt
```

`${task.attempt}`, `${task.cpus}` and `${task.memory}` were filled in by Nextflow, like any other `${…}`. In real scripts, **always pass `${task.cpus}` to your tool**: `bwa mem -t ${task.cpus}`, `samtools sort -@ ${task.cpus}`. Otherwise the tool ignores the CPUs you asked for, or uses more than its share.

### Time limits

```groovy title="timeout.nf"
--8<-- "module04_processes/lesson02_directives/timeout.nf"
```

```text title="Real output (part)"
executor >  local (1)
[20/7dc7e1] SLOW | 0 of 1 ✘
ERROR ~ Error executing process > 'SLOW'

Caused by:
  Process exceeded running time limit (2s)

Command executed:

  sleep 20

Command exit status:
  143
```

Exit status **143** = 128 + 15: killed with `SIGTERM` because time ran out.

### Asking for more than you have

On your laptop, Nextflow refuses a task that asks for more memory than the computer has. In a test with `memory '500.GB'`:

```text title="Real output (part)"
Caused by:
  Task requirement exceeds available memory -- req: 500 GB; avail: 16 GB
```

On a cluster, the same request would wait in the queue (or be rejected by SLURM). Right-size your requests: Lesson 7.5 shows how to read real usage from a report.

### Ignoring failures

With `errorStrategy 'ignore'`, a failing task is reported and skipped. In a test where 1 of 3 tasks exits with 1:

```text title="Real output (part)"
executor >  local (3)
[da/f23756] CHECK (1) | 3 of 3, ignored: 1 ✔
ok_3.txt
ok_1.txt
[d2/c8690d] NOTE: Process `CHECK (2)` terminated with an error exit status (1) -- Error is ignored
```

The run ends with ✔, but sample 2 has **no output**. Use `'ignore'` only when losing a sample is truly acceptable, and check the console for `ignored:`.

!!! gotcha "Gotcha! Braces or no braces?"
    In a test with Nextflow 26.10, `memory 1.GB * task.attempt` **without** braces also grew per attempt (1 GB, then 2 GB): the strict parser notices that the value uses `task`. Older Nextflow versions, nf-core and nearly every pipeline you'll read write the braces. Write them too: `{ … }` tells every reader "this is worked out again for each attempt".

!!! protip "Pro tip: cap retries with `resourceLimits`"
    Memory that doubles on every retry can ask for more than any node has. In Module 12 you'll set `process.resourceLimits` so that requests are capped automatically at what your cluster offers.

---

## D. Guided exercise (about 25 min)

```quiz
id: 4.2-ex-steps
type: steps
concept: directives
label: "Mission steps"
steps:
  - "Run `directives.nf` and read the NOTE lines."
  - "Run `nextflow log last -f name,tag,attempt,cpus,memory,status,exit`."
  - "Open the successful task's `.command.out` and `.command.sh`."
  - "Run `timeout.nf` and find the exit status."
  - "Change `errorStrategy 'retry'` to `errorStrategy 'terminate'` in a copy of `directives.nf` and run it. What happens now?"
```

```quiz
id: 4.2-ex-a
type: number
concept: retries
question: "With `memory { 2.GB * task.attempt }`, how many GB does the **third** attempt of a task request?"
answer: 6
tolerance: 0
unit: GB
explain: "task.attempt is 3 on the third attempt: 2 GB × 3 = 6 GB."
```

```quiz
id: 4.2-ex-b
type: single
concept: retries
question: "With `errorStrategy 'terminate'`, what happened to `directives.nf`?"
options:
  - text: "It still succeeded on the second attempt."
  - text: "The first failure stopped the whole run, with an error report."
    correct: true
  - text: "It skipped the failed sample and finished the other one."
explain: "`'terminate'` (the default) stops everything at the first failure. Watch out: `maxRetries 0` is **not** a way to switch retries off. In a test with Nextflow 26.10, `maxRetries 0` still retried once, like the default of 1. Use a different `errorStrategy` instead."
```

```quiz
id: 4.2-ex-c
type: single
concept: exit-codes
question: "A task fails with exit status 143 on your cluster. What is the most likely cause?"
options:
  - text: "It ran out of memory."
  - text: "It hit its time limit and was terminated (SIGTERM, 128 + 15)."
    correct: true
  - text: "The input file was missing."
explain: "137 (SIGKILL) usually means memory; 143 (SIGTERM) usually means time. A dynamic `time { 2.h * task.attempt }` with retries handles it the same way as memory."
```

---

## E. Independent challenge

`retry.nf` assembles samples (pretend). Each sample needs **3 GB**: with less, the task "runs out of memory" and exits with **137**. A sample called `corrupt` always fails with exit **1**. Fill in the TODOs:

1. `tag` each task with its sample name.
2. Start with **1 GB** and add 1 GB on every new attempt.
3. **Retry** when the exit status is 137, at most 3 retries. On any other error, **stop** the pipeline.

```groovy title="retry.nf (starter)"
--8<-- "module04_processes/lesson02_directives/retry.nf"
```

The checker runs your pipeline on three samples (each must succeed on attempt 3 with 3 GB), then on `kiwi,corrupt`: the corrupt sample must stop the run after **one** attempt.

```quiz
id: 4.2-challenge
type: check
concept: retries
label: "Challenge: auto-checked"
check: 4.2-challenge
command: "bash check_retry.sh"
solution: includes/solutions/4.2/retry.nf
hint: "All three changes are directives at the top of the process. Memory: a closure with `task.attempt`. Error strategy: a closure with `task.exitStatus` and the `condition ? 'a' : 'b'` form. Try `nextflow run retry.nf --samples alpha,corrupt` yourself to see the second test."
explain: "Retrying only what can succeed on a retry is exactly how nf-core pipelines handle errors. Their template's `conf/base.config` says: `errorStrategy = { task.exitStatus in ((130..145) + 104 + (175..177)) ? 'retry' : 'finish' }`, with `maxRetries = 1`."
```

---

## F. Knowledge check

```quiz
id: 4.2-q1
type: open
concept: closures
question: "What is the difference between `memory 2.GB` and `memory { 2.GB * task.attempt }`?"
model: "`memory 2.GB` is a fixed value: every attempt gets 2 GB. The braces make the second one a closure: Nextflow evaluates it again for every attempt, using the current `task.attempt`, so attempt 1 gets 2 GB, attempt 2 gets 4 GB, and so on."
explain: "Braces = 'work it out again each time'."
```

```quiz
id: 4.2-q2
type: single
concept: directives
question: "You set `cpus 8` for an alignment process but the script runs `bwa mem ref.fa reads.fq`. What happens?"
options:
  - text: "bwa uses 8 threads automatically."
  - text: "The task gets 8 CPUs reserved, but bwa uses 1 thread: 7 CPUs are wasted."
    correct: true
  - text: "Nextflow adds `-t 8` for you."
explain: "Directives reserve resources; your command must use them: `bwa mem -t ${task.cpus} …`."
```

```quiz
id: 4.2-q3
type: single
concept: error-strategy
question: "Which error strategy fits a 500-sample run where you'd rather get results for 499 samples than none, and check the failed one later?"
options:
  - text: "`'terminate'`"
  - text: "`'ignore'`"
    correct: true
  - text: "`'retry'` with `maxRetries 100`"
explain: "`'ignore'` carries on without the failed sample. Combine it with a careful look at the `ignored:` count, or use retries first and `'ignore'` as the last resort (a closure can do both)."
```

---

## G. Summary

| Directive | Remember |
|---|---|
| `cpus`, `memory`, `time` | Resources per task → SLURM requests; use `${task.cpus}` in the command |
| `tag "${sample}"` | Readable names on the console and in logs |
| `errorStrategy` | `'terminate'` (default), `'finish'`, `'ignore'`, `'retry'`, or a closure |
| `maxRetries` | Extra attempts allowed with `'retry'` |
| `{ … }` closure | Evaluated again for every attempt; the standard way to write anything that uses `task.*` |
| Exit 137 / 143 | Killed: usually memory / usually time → worth retrying with more |

Next: **Lesson 4.3**: when a task fails anyway, how to find out why, from inside its task folder.

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="4.2"></div>
