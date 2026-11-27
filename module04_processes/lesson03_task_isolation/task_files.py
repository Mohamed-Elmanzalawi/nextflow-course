# task_files.py: what Nextflow does around every task, in Python (Lesson 4.3).
# A fresh folder, a link to each input, the script saved as .command.sh,
# and its output, errors and exit code saved next to it.
import subprocess
import tempfile
from pathlib import Path


def run_task(script, inputs, bash_flags):
    Path("py_work").mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp(dir="py_work"))   # Nextflow: work/xx/yyyy…
    for f in inputs:
        (work / f.name).symlink_to(f.resolve())    # staging: a link, not a copy
    (work / ".command.sh").write_text(script)
    run = subprocess.run(["bash", *bash_flags, ".command.sh"],
                         cwd=work, capture_output=True, text=True)
    (work / ".command.out").write_text(run.stdout)
    (work / ".command.err").write_text(run.stderr)
    (work / ".exitcode").write_text(str(run.returncode))
    return work, run.returncode


if __name__ == "__main__":
    # the FIRST_READ script of hidden_failure.nf
    script = "gzip -cd sample1.fastq | head -n 4 > first_read.txt\n"
    for flags in (["-ue"], ["-euo", "pipefail"]):
        work, code = run_task(script, [Path("data/sample1.fastq")], flags)
        err = (work / ".command.err").read_text().strip()
        size = (work / "first_read.txt").stat().st_size
        print(f"bash {' '.join(flags)}: exit code {code}")
        print(f"  .command.err: {err}")
        print(f"  first_read.txt: {size} bytes")
