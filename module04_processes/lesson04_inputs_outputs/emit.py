# emit.py: split.nf written as plain Python (Lesson 4.4).
# Named outputs are like a NamedTuple; an optional output is like None.
from pathlib import Path
from typing import NamedTuple, Optional


class SplitOut(NamedTuple):
    chunks: list            # path 'chunk_*.fastq', emit: chunks
    n: int                  # path 'n_chunks.txt', emit: n
    # path 'warning.txt', optional: true, emit: warning
    warning: Optional[str]


# process SPLIT
def split(fq, reads_per_chunk):
    lines = fq.read_text().splitlines(keepends=True)
    size = 4 * reads_per_chunk
    out = Path("py_work")
    out.mkdir(exist_ok=True)
    for i in range(0, len(lines), size):
        chunk = out / f"chunk_{fq.stem}_{i // size + 1:02d}.fastq"
        chunk.write_text("".join(lines[i:i + size]))
    # the glob 'chunk_*.fastq'
    chunks = sorted(p.name for p in out.glob(f"chunk_{fq.stem}_*.fastq"))
    # warning.txt exists only sometimes
    warning = "many chunks" if len(chunks) > 4 else None
    return SplitOut(chunks, len(chunks), warning)


if __name__ == "__main__":
    for fq in sorted(Path("data").glob("*.fastq")):
        out = split(fq, 400)                   # out = SPLIT(…, 400)
        print(f"chunks:  {out.chunks}")        # out.chunks.view { … }
        if out.warning is not None:
            print(f"warning: {out.warning}")   # out.warning.view { … }
