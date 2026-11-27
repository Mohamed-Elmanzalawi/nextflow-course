# factories.py: a samplesheet and file pairs, in Python (Lesson 5.2).
import csv
import itertools
from pathlib import Path


# file(path, checkIfExists: true)
def file(path, check_if_exists=False):
    p = Path(path)
    if check_if_exists and not p.exists():
        raise SystemExit(f"ERROR: no such file: {p}")   # stop now, not later
    return p


# channel.fromPath(params.input).splitCsv(header: true): one dict per line
with open("samplesheet.csv") as fh:
    rows = list(csv.DictReader(fh))
for row in rows:
    print(f"csv row:   {row}")

# .map { row -> tuple(row.sample, file(row.fastq_1, checkIfExists: true), …) }
samples = [(row["sample"],
            file(row["fastq_1"], True),
            file(row["fastq_2"], True)) for row in rows]
for sample_id, r1, r2 in samples:
    print(f"tuple:     {sample_id} {r1.name} {r2.name}")

# channel.fromFilePairs('data/*_R{1,2}.fastq.gz'): the id is what * matched
files = sorted(Path("data").glob("*_R[12].fastq.gz"))
by_id = lambda f: f.name.rsplit("_R", 1)[0]
for sample_id, pair in itertools.groupby(files, key=by_id):
    print(f"pairs:     {sample_id} {[f.name for f in pair]}")
