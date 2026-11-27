---
lesson: "5.3"
module: 5
level: 1
---

# Lesson 5.3: Core operators

!!! info "About this lesson"
    **You'll learn:**

    - the operators behind nearly every pipeline: `map`, `filter`, `view`, `collect`, `flatten`, `mix`, `join`, `groupTuple`, `combine`, `sum`, `count`;
    - which Python idiom each one corresponds to;
    - how to build an operator chain one step at a time, checking each step with `view()`.

    **Why it matters:** processes do the work, but operators decide **what goes where**: pairing a BAM with its index, grouping lanes of one sample, matching tumour with normal, running every sample against every reference. If you can reshape channels, you can wire any pipeline.

    **Time:** about 1.5 h · **Level:** Beginner · **Needs:** Lesson 5.2

    **Docs:** [Operators](https://docs.seqera.io/nextflow/reference/operator) · [`join`](https://docs.seqera.io/nextflow/reference/operator#join) · [`groupTuple`](https://docs.seqera.io/nextflow/reference/operator#grouptuple) · [`combine`](https://docs.seqera.io/nextflow/reference/operator#combine)

!!! flo "Flo says"
    Operators are like Python's built-ins for lists, except they work on channels, which deliver items over time. Same ideas, new names. Let's map them.

---

## A. Concept

### Operators in one table

| Operator | Does | Python analogy |
|---|---|---|
| `map { x -> … }` | Transforms every item | `map(f, items)` / `[f(x) for x in items]` |
| `filter { x -> … }` | Keeps items where the closure is true | `[x for x in items if cond(x)]` |
| `view { x -> … }` | Prints every item; passes them on unchanged | `print` |
| `collect()` | All items → **one list** (a value channel) | `list(items)` |
| `flatten()` | Unpacks lists into single items | `itertools.chain.from_iterable` |
| `mix(other)` | Merges two channels into one, in arrival order | concatenating two queues |
| `join(other)` | Matches items **by key** (first element) | merging two dicts by key |
| `groupTuple()` | Items with the same key → one item with a list | `defaultdict(list)` / `groupby` |
| `combine(other)` | Every item with every item of the other | `itertools.product` |
| `sum()` / `count()` | One number | `sum(items)` / `len(items)` |

A **key** is the first element of a tuple: in `['cov_a', 100]` the key is `'cov_a'`.

--8<-- "includes/anim/operators.html"

Operators can be **chained**; each one returns a new channel:

```groovy
reads.filter { f -> f.name.startsWith('cov') }
     .map { f -> tuple(f.simpleName, f) }
     .view()
```

!!! analogy "Real-life analogy: sorting the post"
    `filter` throws away junk mail. `map` re-addresses every letter. `groupTuple` puts all letters for one household in one bundle. `join` staples each letter to its matching return slip. `combine` sends every newsletter to every address.

---

## B. Demonstration

=== "Nextflow"

    ```groovy title="operators.nf"
    --8<-- "module05_channels/lesson03_operators/operators.nf"
    ```

=== "Python equivalent"

    ```python title="operators.py"
    --8<-- "module05_channels/lesson03_operators/operators.py"
    ```

    ```bash title="Terminal"
    python3 operators.py | sort
    ```

    ```text title="Real output: identical, line for line, to the Nextflow output below"
    collect:    [1, 2, 3, 4, 5]
    combine:    [cov_a, GRCh38]
    combine:    [cov_a, MN908947]
    …
    range:      3
    sum:        15
    ```

!!! note "Where the analogy stops"
    Python works on finished lists, so its order never changes. Channels deliver items as they're produced, so in Nextflow the order can change from run to run (that's why both commands end in `| sort`), and `collect`, `sum` and `count` must wait until their channel has delivered its last item.

```bash title="Terminal"
cd "$COURSE"/module05_channels/lesson03_operators
nextflow -q run operators.nf | sort
```

`-q` (quiet) hides the banner and the progress display; `| sort` groups the lines by operator, because the channels run at the same time and their lines arrive interleaved.

```text title="Real output"
collect:    [1, 2, 3, 4, 5]
combine:    [cov_a, GRCh38]
combine:    [cov_a, MN908947]
combine:    [cov_b, GRCh38]
combine:    [cov_b, MN908947]
count:      5
filter:     1
filter:     3
filter:     5
flatten:    1
flatten:    2
flatten:    3
groupTuple: [s1, [L001.fq, L002.fq]]
groupTuple: [s2, [L001.fq]]
join:       [cov_a, 100, 38.2]
join:       [cov_b, 100, 37.6]
map:        10
map:        20
map:        30
map:        40
map:        50
mix:        a
mix:        b
mix:        z
range:      1
range:      2
range:      3
sum:        15
```

Notice `join`: the GC values arrived in the order `cov_b`, `cov_a`, but each was matched to the right read count **by key**, not by position.

---

## C. Code walkthrough

### The closure parameter

```groovy
numbers.map { n -> n * 10 }
```

`n ->` names the item. With tuples, name each part: `{ id, count -> … }`. In older code you'll see the implicit name `it` (`map { it * 10 }`). Nextflow's strict syntax deprecates that: **name your parameters**. A parameter you don't use starts with `_`, which keeps `nextflow lint` quiet: `counts.map { _id, n -> n }`.

### `join` vs `combine`

Both take two channels; they do opposite things:

| | `join` | `combine` |
|---|---|---|
| Pairs | Only items with the **same key** | **Every** item with every item |
| 2 + 2 items | 2 results (1 per key) | 4 results |
| Typical use | Sample's BAM with the same sample's VCF | Every sample × every reference/panel/parameter |

!!! gotcha "Gotcha! `join` silently drops items without a partner"
    If `cov_c` has a read count but no GC value, `join` simply leaves it out: no error. Add `failOnMismatch: true` while developing to turn that into an error; in a test it stopped with *Join mismatch for the following entries: key=s2 values=[bam2]*. With `remainder: true`, unmatched items are kept instead, with `null` for the missing part: `[s2, bam2, null]`. (This is the Lesson 1.2 `join` story again, in Nextflow.)

!!! gotcha "Gotcha! `groupTuple` waits for the whole channel"
    `groupTuple()` can only emit a group when it knows no more items with that key are coming, which by default is when the channel **ends**. A per-sample step after `groupTuple` therefore starts only after all upstream items are done. With a known group size, `groupTuple(size: 4)` emits each group as soon as it's complete.

!!! protip "Pro tip: build chains with `view()`"
    Add one operator, `view()` the result, run with `-q`, check. Then add the next. Debugging a five-operator chain all at once is much harder than building it one step at a time.

---

## D. Guided exercise (about 30 min)

```quiz
id: 5.3-ex-steps
type: steps
concept: operators
label: "Mission steps"
steps:
  - "Run `nextflow -q run operators.nf | sort` and match each line to its operator."
  - "Add `.view()` after `numbers.filter { n -> n % 2 == 1 }.map { n -> n * 100 }` and predict the output first."
  - "Run `nextflow -q run puzzle.nf` (the challenge) as it is, and read the GOAL comments."
```

```quiz
id: 5.3-ex-a
type: number
concept: operators
question: "`channel.of('a', 'b', 'c').combine(channel.of(1, 2))`: how many items?"
answer: 6
tolerance: 0
unit: items
explain: "`combine` makes every pair: 3 × 2 = 6."
```

```quiz
id: 5.3-ex-b
type: single
concept: operators
question: "Lanes `['s1', 'L1']`, `['s1', 'L2']`, `['s2', 'L1']` go into `groupTuple()`. What comes out?"
options:
  - text: "`[s1, L1, L2, s2, L1]`"
  - text: "`[s1, [L1, L2]]` and `[s2, [L1]]`"
    correct: true
  - text: "`[[s1, s1, s2], [L1, L2, L1]]`"
explain: "One item per key, with a list of everything else. That's exactly the demo's `groupTuple` output."
```

```quiz
id: 5.3-ex-c
type: single
concept: operators
question: "Channel A has `[s1, bam]`, `[s2, bam]`, `[s3, bam]`; channel B has `[s1, vcf]`, `[s3, vcf]`. What does `A.join(B)` give?"
options:
  - text: "3 items; s2 gets `null` for its VCF."
  - text: "2 items: `[s1, bam, vcf]` and `[s3, bam, vcf]`. s2 is dropped."
    correct: true
  - text: "An error, because s2 has no VCF."
explain: "By default `join` emits only keys found in both channels, silently. `failOnMismatch: true` would make it an error; `remainder: true` would keep s2."
```

---

## E. Independent challenge

`puzzle.nf` has six parts, **A** to **F**. Each one prints a channel with `view()`. Add operators **before** each `view()` so the printed output matches the GOAL comment. Don't change the input channels.

```groovy title="puzzle.nf (starter)"
--8<-- "module05_channels/lesson03_operators/puzzle.nf"
```

Run it with `nextflow -q run puzzle.nf | sort` as you go. The checker runs it the same way and checks each part separately, so you can see which ones are already right.

```quiz
id: 5.3-challenge
type: check
concept: operators
label: "Challenge: auto-checked"
check: 5.3-challenge
command: "bash check_puzzle.sh"
solution: includes/solutions/5.3/puzzle.nf
hint: "A: two operators. B: one. C: one. D: two (make every pair, then keep the sensible ones: `s.startsWith('cov')` is true for SARS-CoV-2 samples). E: first keep only the number of each pair with `map`, then one more operator. F: two."
explain: "Six parts, about ten operators: that's the vocabulary of most real pipelines."
```

---

## F. Knowledge check

```quiz
id: 5.3-q1
type: open
concept: operators
question: "You have one channel of `[sample, bam]` and one of `[sample, bai]` (the BAM index). Which operator puts each BAM with its own index, and why not `combine`?"
model: "`join`, which matches items by their key (the sample name), giving `[sample, bam, bai]`. `combine` would pair every BAM with every index, including other samples' indexes, which is wrong (and grows as n × n)."
explain: "Same key → `join`. Every pair → `combine`."
```

```quiz
id: 5.3-q2
type: single
concept: operators
question: "Which operator turns a channel of 200 per-sample files into a single item, so one process sees all 200?"
options:
  - text: "`flatten()`"
  - text: "`collect()`"
    correct: true
  - text: "`mix()`"
explain: "`collect()` (Lesson 3.2). `flatten()` goes the other way: lists → single items."
```

```quiz
id: 5.3-q3
type: single
concept: closures
question: "Which closure is written in the style Nextflow's strict syntax recommends?"
options:
  - text: "`map { it * 2 }`"
  - text: "`map { n -> n * 2 }`"
    correct: true
explain: "The implicit `it` is deprecated: name your closure parameters (and prefix unused ones with `_`)."
```

---

## G. Summary

| Need | Operator |
|---|---|
| Change every item | `map` |
| Keep some items | `filter` |
| All items as one list | `collect` |
| Lists → single items | `flatten` |
| One channel from two | `mix` |
| Match by key | `join` (drops unmatched items silently) |
| Group by key | `groupTuple` (waits for the end, unless you give `size:`) |
| Every pair | `combine` |
| One number | `sum`, `count` |
| Look inside | `view` + <code>nextflow -q run … &#124; sort</code> |

Next: **Lesson 5.4** puts it all together with the **meta map**: the `[meta, files]` pattern used by every nf-core module.

---

## H. Your progress

<div class="nb-lesson-progress" data-lesson="5.3"></div>
