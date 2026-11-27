# main.py: main.nf written as plain Python (Lesson 3.2).
import time
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path


# process COUNT_READS
def count_reads(fq):
    time.sleep(2)
    n = sum(1 for _ in open(fq)) // 4      # awk 'END { print NR / 4 }'
    return f"{fq.stem}\t{n}"


# process SUMMARISE
def summarise(counts):
    return "\n".join(counts)               # cat ${counts} > summary.tsv


if __name__ == "__main__":
    # reads_ch = channel.fromPath('data/*.fastq')
    reads = sorted(Path("data").glob("*.fastq"))
    # counts_ch = COUNT_READS(reads_ch): Nextflow runs tasks in parallel
    # by itself; in Python you ask for it
    with ProcessPoolExecutor() as pool:
        counts = list(pool.map(count_reads, reads))
    # summary_ch = SUMMARISE(counts_ch.collect())
    summary = summarise(counts)
    # summary_ch.view()
    print(summary)
