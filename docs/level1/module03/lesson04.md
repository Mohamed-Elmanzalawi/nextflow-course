---
lesson: "3.4"
module: 3
level: 1
---

# Lesson 3.4: The `work/` folder and `-resume`

!!! info "About this lesson"
    **You'll learn:**

    - how `-resume` skips tasks that already finished;
    - what goes into a task's **hash**, and so what makes a task run again;
    - how to see past runs with `nextflow log`;
    - how to clean `work/` safely with `nextflow clean`.

    **Why it matters:** a real pipeline can run for days. When sample 157 of 200 fails (Lesson 1.1's nightmare), you fix the problem and add `-resume`. Nextflow redoes **only** what's needed, so you lose minutes instead of days.

    **Time:** about 1 h · **Level:** Beginner · **Needs:** Lesson 3.3

    **Docs:** [Caching and resuming](https://docs.seqera.io/nextflow/cache-and-resume) · [`cache` directive](https://docs.seqera.io/nextflow/reference/process/directives/cache) · [`nextflow log`](https://docs.seqera.io/nextflow/reference/cli/log) · [`nextflow clean`](https://docs.seqera.io/nextflow/reference/cli/clean)

!!! flo "Flo says"
    In Lesson 3.1 every run created new folders and threw the old work away. Today you meet the one option you'll type more than any other: `-resume`.

---

## A. Concept

### Every task has a fingerprint

Before running a task, Nextflow computes a **hash**: a fingerprint of everything that could change the task's result. From the Nextflow docs, it includes:

- the **process name** and the task's **script** (after `${…}` values are filled in);
- the task's **inputs**: for files, their **path, size and last-modified time**;
- the **container** image or **conda** environment, when one is in use (for example with `-profile docker`);
- global variables used in the script, and a few more items.

The hash **is** the task folder's name: `work/9e/24edb3…`. With **`-resume`**, before running a task Nextflow asks: *"Did a task with exactly this hash already finish successfully in the previous run?"* If yes, it reuses that folder's outputs instead of running again. That's a **cached** task.

--8<-- "includes/anim/resume_cache.html"

!!! analogy "Real-life analogy: a lab notebook with checksums"
    Before repeating an experiment you check your notebook: same protocol, same reagent lot, same sample? Then the result on page 42 is still valid and you don't redo it. Change the protocol (the script) or the sample (an input), and you must run it again.

### The same idea in Python

`resume.py` counts reads the slow way, but first computes a fingerprint from the script and each input file's path, size and modification time, and looks for a folder with that name in `py_work/`:

```python title="resume.py"
--8<-- "module03_first_pipeline/lesson04_resume/resume.py"
```

```bash title="Terminal"
bash ../make_data.sh
python3 resume.py
python3 resume.py
touch data/sample1.fastq
python3 resume.py
```

```text title="Real output (your hashes will differ: they include the full path)"
[27/91ecef] sample1.fastq: ran
[1f/263d27] sample2.fastq: ran
[ec/dc5c79] sample3.fastq: ran
[27/91ecef] sample1.fastq: cached
[1f/263d27] sample2.fastq: cached
[ec/dc5c79] sample3.fastq: cached
[a9/36c3ce] sample1.fastq: ran
[1f/263d27] sample2.fastq: cached
[ec/dc5c79] sample3.fastq: cached
```

`touch` changed only the timestamp of `sample1.fastq`, but the timestamp is part of the fingerprint, so that one task ran again. Nextflow behaves exactly the same way, as you'll see in section B.

!!! note "Where the analogy stops"
    Nextflow's hash also covers the container or conda environment and the values filled into the script, and with `-resume` it reuses only tasks that **succeeded**. Python's `functools.cache` is the in-memory cousin of this idea; it forgets everything when the program ends.

### A ripple effect

When one task re-runs, its **outputs** are new files, so the next task's **inputs** have changed too, and it re-runs as well. In the animation, step ④: `sample1` changed, so its count file is new, so `SUMMARISE` (which reads all count files) runs again. Tasks that don't depend on `sample1` stay cached.

---

## B. Demonstration

The pipeline is Lesson 3.3's, with the 2-second `sleep` back in `COUNT_READS`, so you can **feel** the difference:

```groovy title="main.nf"
--8<-- "module03_first_pipeline/lesson04_resume/main.nf"
```

### 1. A first run, then the same run with `-resume`

```bash title="Terminal"
cd "$COURSE"/module03_first_pipeline/lesson04_resume
bash ../make_data.sh
nextflow run main.nf
nextflow run main.nf -resume
```

??? predict "Predict: what will the second run print, and how long will it take?"
    Real output (Nextflow 26.10.7). The first run took about 5 s:

    ```text title="Real output: first run"
    Launching `main.nf` [chaotic_einstein] revision: a94adc72ff

    executor >  local (4)
    [9e/24edb3] COUNT_READS (3) | 3 of 3 ✔
    [ac/cbd44b] SUMMARISE       | 1 of 1 ✔
    ```

    The second about 2 s, and **no task ran**: there's no `executor > local (…)` line at all.

    ```text title="Real output: with -resume"
    Launching `main.nf` [nostalgic_ochoa] revision: a94adc72ff

    [8d/a6d170] COUNT_READS (2) | 3 of 3, cached: 3 ✔
    [ac/cbd44b] SUMMARISE       | 1 of 1, cached: 1 ✔
    ```

    `cached: 3` means all three counting tasks were reused. `SUMMARISE` shows the **same** hash, `ac/cbd44b`, as in the first run: it's the very same folder. (The banner lines and the Outputs section are left out here to save space.)

### 2. Change one process's script

Edit `SUMMARISE` in `main.nf` so it sorts by read count, largest first: change `sort` to `sort -k2,2nr`. Then:

```bash title="Terminal"
nextflow run main.nf -resume
cat results/summary.tsv
```

```text title="Real output"
Launching `main.nf` [nauseous_wozniak] revision: dc41e3bc76

executor >  local (1)
[8d/a6d170] COUNT_READS (2) | 3 of 3, cached: 3 ✔
[ae/fe0694] SUMMARISE       | 1 of 1 ✔

sample3	1500
sample2	1250
sample1	1000
```

Only `SUMMARISE` ran (`local (1)`), with a **new** hash. The `revision` changed too, because the script's text changed.

### 3. Touch one input file

`touch` changes a file's timestamp but not its content:

```bash title="Terminal"
touch data/sample1.fastq
nextflow run main.nf -resume
```

```text title="Real output"
executor >  local (2)
[c6/c51dce] COUNT_READS (3) | 3 of 3, cached: 2 ✔
[43/4ba9f4] SUMMARISE       | 1 of 1 ✔
```

Two tasks ran: the `sample1` count (its input's timestamp changed) and `SUMMARISE` (the ripple effect).

### 4. Add a sample

```bash title="Terminal"
bash ../make_data.sh 4          # adds sample4, keeps the other three untouched
nextflow run main.nf -resume
cat results/summary.tsv
```

```text title="Real output"
Created 1 new FASTQ file(s) in data/ (kept 3 existing)

executor >  local (2)
[c4/f0c585] COUNT_READS (2) | 4 of 4, cached: 3 ✔
[bd/1f775a] SUMMARISE       | 1 of 1 ✔

sample4	1750
sample3	1500
sample2	1250
sample1	1000
```

One new counting task, three from the cache. On 200 real samples that's the difference between one hour and three days.

---

## C. Code walkthrough

### `nextflow log`: the history of runs

```bash title="Terminal"
nextflow log
```

```text title="Real output"
TIMESTAMP               DURATION        RUN NAME                STATUS  REVISION ID     SESSION ID                              COMMAND
2026-11-26 12:07:32     3.1s            chaotic_einstein        OK      a94adc72ff      33f72432-3e24-4f99-8d83-5ce9c49dd0f5    nextflow run main.nf
2026-11-26 12:07:36     1.5s            nostalgic_ochoa         OK      a94adc72ff      33f72432-3e24-4f99-8d83-5ce9c49dd0f5    nextflow run main.nf -resume
2026-11-26 12:07:38     1.9s            nauseous_wozniak        OK      dc41e3bc76      33f72432-3e24-4f99-8d83-5ce9c49dd0f5    nextflow run main.nf -resume
2026-11-26 12:07:41     3.3s            cheeky_boyd             OK      dc41e3bc76      33f72432-3e24-4f99-8d83-5ce9c49dd0f5    nextflow run main.nf -resume
2026-11-26 12:07:45     3.8s            evil_spence             OK      dc41e3bc76      33f72432-3e24-4f99-8d83-5ce9c49dd0f5    nextflow run main.nf -resume
```

Ask about the tasks of one run by its name:

```bash title="Terminal"
nextflow log evil_spence -f name,hash,status
```

```text title="Real output"
COUNT_READS (2) c4/f0c585       COMPLETED
COUNT_READS (2) 8d/a6d170       CACHED
COUNT_READS (3) c6/c51dce       CACHED
COUNT_READS (1) 56/265be8       CACHED
SUMMARISE       bd/1f775a       COMPLETED
```

`COMPLETED` tasks ran in this run, `CACHED` ones were reused. (The numbers in brackets are just the order in which tasks were created in that run, so two tasks can share one.) `nextflow log -l` lists every field you can ask for, including `workdir`, `duration` and `exit`.

!!! info "Which run does `-resume` resume?"
    The **session ID** column: every `-resume` continues the session of the **previous** run, so all five runs above share one session. A run **without** `-resume` starts a new session, and its cache starts empty. You can also resume an older run by name: `nextflow run main.nf -resume chaotic_einstein`.

### `nextflow clean`: tidying `work/`

`work/` keeps every task folder of every run. To delete the folders that the **last** run doesn't use, first ask what would go (`-n`, dry run), then do it (`-f`, force):

```bash title="Terminal"
nextflow clean -n -but last
nextflow clean -f -but last
```

```text title="Real output: the first lines of the dry run (paths shortened)"
Would remove …/work/ac/cbd44bc6e1dd2871fdc25905ed9c3e
Would remove …/work/9e/24edb3b5c6135464336e10414834b0
Would remove …/work/ae/fe0694de899feb3087e521f8ab66c6
```

The dry run listed 4 folders in total.

After `-f`, `work/` went from 9 task folders (160 KB) to 5 (84 KB). A final `-resume` still found **all 5 tasks in the cache**, because the last run's folders were kept.

!!! gotcha "Gotcha! `rm -rf work` throws the cache away"
    Deleting `work/` by hand is allowed, but afterwards `-resume` has nothing to resume, and every symlink you published points into nothing (Lesson 3.3). Use `nextflow clean -but last`, and publish final results with `mode 'copy'`.

### When timestamps lie: `cache 'lenient'`

On a cluster's shared file system, copying or syncing data can change file timestamps without changing their content. Then `-resume` re-runs everything, like step 3 above, but for **every** file. The `cache` directive changes what Nextflow fingerprints:

| `cache` value | Input files are fingerprinted by |
|---|---|
| `true` (default) | path, size and last-modified time |
| `'lenient'` | path and size only: timestamps are ignored |
| `'deep'` | the file **content** (slow for big files) |
| `false` | caching off: the task always runs |

```groovy
process COUNT_READS {
    cache 'lenient'
    …
}
```

!!! funfact "Fun fact"
    Switching a process to `cache 'lenient'` changes how its hash is computed, so the **first** `-resume` after the switch runs every task of that process again. In the test run, all 4 `COUNT_READS` tasks re-ran once; after that, `touch` no longer triggered anything.

!!! protip "Pro tip: make `-resume` a habit"
    There's almost no reason **not** to add `-resume`. If nothing is cached, it simply runs everything. Many people put it in every command.

---

## D. Guided exercise (about 25 min)

```quiz
id: 3.4-ex-steps
type: steps
concept: resume
label: "Mission steps"
steps:
  - "Run `main.nf`, then run it again with `-resume`. Compare the time and the `cached:` counts."
  - "Change `sort` to `sort -k2,2nr` in `SUMMARISE` and resume."
  - "`touch data/sample1.fastq` and resume."
  - "Add a sample with `bash ../make_data.sh 4` and resume."
  - "Run `nextflow log`, then `nextflow log <last run name> -f name,hash,status`."
  - "Run `nextflow clean -n -but last`, then `-f`, then resume one more time."
```

```quiz
id: 3.4-ex-a
type: number
concept: resume
question: "In step 3 (`touch data/sample1.fastq`, then `-resume`), how many tasks actually **ran**?"
answer: 2
tolerance: 0
unit: tasks
explain: "The `sample1` counting task (its input's timestamp changed) and `SUMMARISE` (one of its inputs, the sample1 count file, is a new file). The other two counting tasks came from the cache."
```

```quiz
id: 3.4-ex-b
type: single
concept: resume
question: "You run `nextflow run main.nf` **without** `-resume` after many resumed runs. What happens?"
options:
  - text: "Nextflow resumes anyway, because nothing changed."
  - text: "Every task runs again, in a new session with an empty cache; the old folders stay in `work/`."
    correct: true
  - text: "Nextflow deletes the old `work/` folders first."
explain: "No `-resume`, no reuse. The old folders are still on disk, and you could even resume one of those older runs by name."
```

```quiz
id: 3.4-ex-c
type: multi
concept: task-hash
question: "Which of these changes make `COUNT_READS` run again under `-resume` (default caching)? Tick all that apply."
options:
  - text: "Editing the `awk` command in COUNT_READS's script"
    correct: true
  - text: "`touch` on its input FASTQ file"
    correct: true
  - text: "Editing only the `SUMMARISE` process"
  - text: "Changing `--title` when the title is passed only to SUMMARISE"
  - text: "Adding `cpus 2` to COUNT_READS"
explain: "A task re-runs when **its own** fingerprint changes: its script, its inputs (path, size, timestamp) or its software environment. Changes that only affect other processes leave it cached. Resource directives such as `cpus` aren't part of the fingerprint either: in a test run, adding `cpus 2` left all 4 tasks cached."
```

---

## E. Independent challenge

Copy `main.nf` to **`resume.nf`** and make two changes:

1. `summary.tsv` must start with a header line: `sample`, a **tab**, `reads`. Then come the sorted counts, as before.
2. `COUNT_READS` must survive "timestamp-only" changes: after `touch` on every FASTQ file, `-resume` must still take all `COUNT_READS` tasks from the cache.

The checker runs your pipeline three times on fresh data: a first run; then `touch` on every input and `-resume`; then one **new** sample and `-resume`. It reads Nextflow's **trace file** to see which tasks ran and which were cached.

```quiz
id: 3.4-challenge
type: check
concept: resume
label: "Challenge: auto-checked"
check: 3.4-challenge
command: "bash check_resume.sh"
solution: includes/solutions/3.4/resume.nf
hint: "Part 1: write the header with `printf 'sample\\treads\\n' > summary.tsv`, then **append** the counts with `>>`. Part 2: one directive in `COUNT_READS`, from the table in section C."
explain: "You just made a pipeline that resumes correctly on a shared file system, and you proved it with a test that reads the trace, the same way you'll test real pipelines in Module 9."
```

---

## F. Knowledge check

```quiz
id: 3.4-q1
type: open
concept: task-hash
question: "In your own words: how does Nextflow decide whether a task can be taken from the cache?"
model: "It computes a hash from everything that could affect the task's result: the process name, the script with its values filled in, the input files (path, size and timestamp by default), the container or conda environment, and so on. With `-resume`, if a task with the same hash finished successfully in the resumed session, Nextflow reuses its folder and outputs instead of running it."
explain: "Same fingerprint → same result → no need to run again."
```

```quiz
id: 3.4-q2
type: single
concept: resume
question: "Your 200-sample run failed at sample 157 because of a typo in the `ALIGN` script. You fix the typo and resume. What re-runs?"
options:
  - text: "All 200 samples, from the first step."
  - text: "The `ALIGN` tasks (their script changed) and everything downstream of them; earlier steps such as QC and trimming come from the cache."
    correct: true
  - text: "Only sample 157."
explain: "Fixing the `ALIGN` script changes the hash of **every** `ALIGN` task, so all of them run again, along with what depends on their outputs. Steps before `ALIGN` are untouched and cached. That's still a huge saving."
```

```quiz
id: 3.4-q3
type: single
concept: cache-modes
question: "On your cluster, data is re-synced every night, which updates timestamps but not contents. Which setting stops `-resume` from re-running everything?"
options:
  - text: "`cache false`"
  - text: "`cache 'lenient'`"
    correct: true
  - text: "`cache 'deep'`"
explain: "`lenient` ignores timestamps (path and size only). `deep` would also work, but it reads every byte of every input, which is slow for big files. `false` turns caching off completely."
```

---

## G. Summary

| Concept | Remember |
|---|---|
| Task hash | Fingerprint of the script, inputs (path, size, timestamp), environment, … = the task folder's name |
| `-resume` | Reuses finished tasks with the same hash from the previous session |
| Ripple effect | A re-run task makes new outputs, so the tasks downstream re-run too |
| `cache 'lenient'` | Ignore timestamps; for shared/synced file systems |
| `nextflow log` | List past runs; `nextflow log <run> -f name,hash,status` lists their tasks |
| `nextflow clean -f -but last` | Delete task folders the last run doesn't need |

!!! flo "Module 3 complete!"
    You wrote a parameterised pipeline that publishes its results and resumes like a pro. **Module 4** zooms into the process itself: every section, the directives that control resources and retries, and how to debug a task that fails.

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="3.4"></div>
