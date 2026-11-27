# resume.py: how -resume decides, written as plain Python (Lesson 3.4).
# Each task gets a fingerprint (hash) of its script and its inputs. If a
# folder with that name already holds a result, it is reused, not recomputed.
import hashlib
import time
from pathlib import Path

# The task's script: edit it and every hash changes.
SCRIPT = "awk 'END { print NR / 4 }'"


def task_hash(fq):
    # an input file counts by its path, size and modification time
    st = fq.stat()
    key = f"COUNT_READS|{SCRIPT}|{fq.resolve()}|{st.st_size}|{st.st_mtime_ns}"
    h = hashlib.md5(key.encode()).hexdigest()
    return f"{h[:2]}/{h[2:8]}"     # like Nextflow's [9e/24edb3]


def count_reads(fq):
    h = task_hash(fq)
    # py_work/ plays the part of work/
    done = Path("py_work") / h / "count.txt"
    if done.exists():
        print(f"[{h}] {fq.name}: cached")
        return int(done.read_text())
    time.sleep(2)                              # the slow part
    n = sum(1 for _ in open(fq)) // 4
    done.parent.mkdir(parents=True, exist_ok=True)
    done.write_text(str(n))
    print(f"[{h}] {fq.name}: ran")
    return n


if __name__ == "__main__":
    for fq in sorted(Path("data").glob("*.fastq")):
        count_reads(fq)
