# meta.py: the meta-map pattern of meta.nf, in Python (Lesson 5.4).
# Each item is (meta, files): a dict of facts about the sample, and its files.
import csv
import gzip
from pathlib import Path


def show(v):
    """Print dicts and lists the way Nextflow prints maps and lists."""
    if isinstance(v, dict):
        return "[" + ", ".join(f"{k}:{show(x)}" for k, x in v.items()) + "]"
    if isinstance(v, list):
        return "[" + ", ".join(show(x) for x in v) + "]"
    return str(v).lower() if isinstance(v, bool) else str(v)


# process COUNT_PAIRS
#   input:  tuple val(meta), path(reads)
#   output: tuple val(meta), …
def count_pairs(meta, reads):
    with gzip.open(reads[0], "rt") as fh:      # ${reads[0]}: R1 only
        n = sum(1 for _ in fh) // 4
    return meta, n


# .splitCsv(header: true).map { row -> … tuple(meta, [r1, r2]) }
samples = []
with open("samplesheet.csv") as fh:
    for row in csv.DictReader(fh):
        meta = {"id": row["sample"], "condition": row["condition"],
                "single_end": False}
        samples.append((meta, [Path(row["fastq_1"]), Path(row["fastq_2"])]))
for meta, reads in samples:
    print(f"in:  {show(meta)} {show([f.name for f in reads])}")

counted = [count_pairs(meta, reads) for meta, reads in samples]
for meta, n in counted:
    # meta + [read_pairs: n]: a NEW map
    new_meta = {**meta, "read_pairs": n}
    print(f"out: {show(new_meta)}")

# Why not change meta in place? Two channels can hold the same map object:
first_meta = samples[0][0]
same_object = counted[0][0]          # what COUNT_PAIRS passed on
same_object["read_pairs"] = 0        # an in-place change "here"
print(f"oops: {show(first_meta)}")   # changed the input "there" too
