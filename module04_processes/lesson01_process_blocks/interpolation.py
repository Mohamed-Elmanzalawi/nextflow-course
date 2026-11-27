# interpolation.py: the script block of blocks.nf as an f-string (Lesson 4.1).
# Two languages share one string here too, but the clash is different:
#   Python fills {…}, so awk's own braces are doubled: {{ }}
#   Nextflow fills ${…}, so Bash's own $ gets a backslash: \$
import subprocess


def length_stats(fq, min_len):
    script = f"""awk -v min={min_len} '
    NR % 4 == 2 {{ reads++; if (length($0) >= min) long++ }}
    END {{ print "reads:", reads, "long enough:", long }}
' {fq}
echo "bash version: $BASH_VERSION"
"""
    print("--- the script Bash receives (Nextflow saves it as .command.sh):")
    print(script)
    run = subprocess.run(["bash", "-c", script],
                         capture_output=True, text=True, check=True)
    return run.stdout


if __name__ == "__main__":
    out = length_stats("data/sample1.fastq", 50)
    print("--- its output:")
    print(out, end="")
