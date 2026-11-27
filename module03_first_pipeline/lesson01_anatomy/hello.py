# hello.py: hello.nf written as plain Python (Lesson 3.1).
from pathlib import Path


# process SAY_HELLO { … }
def say_hello():
    # Nextflow picks a fresh folder in work/ for you
    out = Path("py_work/hello.txt")
    out.parent.mkdir(exist_ok=True)
    # script: echo 'Hello from Nextflow!' > hello.txt
    out.write_text("Hello from Python!\n")
    # output: path 'hello.txt'
    return out


# workflow { SAY_HELLO() }
if __name__ == "__main__":
    print(say_hello())
