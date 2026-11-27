# operators.py: every operator of operators.nf, in plain Python (Lesson 5.3).
# show() prints lists the way Nextflow does, so `python3 operators.py | sort`
# can be compared line by line with `nextflow -q run operators.nf | sort`.
import itertools
from collections import defaultdict


def show(v):
    if isinstance(v, (list, tuple)):
        return "[" + ", ".join(show(x) for x in v) + "]"
    return str(v)


def view(label, items):
    for v in items:
        print(f"{label + ':':<12}{show(v)}")


numbers = [1, 2, 3, 4, 5]          # channel.of(1, 2, 3, 4, 5)

# .map { n -> n * 10 }
view("map", [n * 10 for n in numbers])
# .filter { n -> n % 2 == 1 }
view("filter", [n for n in numbers if n % 2 == 1])
# .collect(): ONE item, a list
view("collect", [list(numbers)])
# .flatten()
view("flatten", itertools.chain.from_iterable([[1, 2], [3]]))
# .mix(channel.of('z'))
view("mix", ["a", "b"] + ["z"])

# reads.join(gc): match by key, the first element
reads = [["cov_a", 100], ["cov_b", 100]]
gc = dict([["cov_b", 37.6], ["cov_a", 38.2]])
view("join", [[k, n, gc[k]] for k, n in reads if k in gc])

# lanes.groupTuple()
lanes = [["s1", "L001.fq"], ["s2", "L001.fq"], ["s1", "L002.fq"]]
groups = defaultdict(list)
for sample, lane in lanes:
    groups[sample].append(lane)
view("groupTuple", [[k, v] for k, v in groups.items()])

# samples.combine(refs)
samples = ["cov_a", "cov_b"]
refs = ["MN908947", "GRCh38"]
view("combine", [list(p) for p in itertools.product(samples, refs)])

view("sum", [sum(numbers)])        # .sum()
view("count", [len(numbers)])      # .count()
view("range", range(1, 4))         # channel.of(1..3)
