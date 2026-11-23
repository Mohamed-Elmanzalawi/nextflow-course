# Setup: running this site

The course website is built with [MkDocs Material](https://squidfunk.github.io/mkdocs-material/), the same tool used for the official [Nextflow training](https://training.nextflow.io/latest/). Everything lives in your project folder.

## Open the site

```bash title="Terminal"
cd ~/Desktop/Projects/learning_nextflow
conda activate nf-course
mkdocs serve
```

Then open <http://127.0.0.1:8000> in your browser.

- The page reloads automatically whenever a lesson file changes.
- Stop the server with ++ctrl+c++.

!!! note "The `nf-course` conda environment"
    This environment holds only the website tooling (`mkdocs-material`). It does **not** contain Nextflow. Lesson 2.2 installs Nextflow separately.

## Where things live

```text
learning_nextflow/
├── mkdocs.yml                  # website configuration
├── docs/                       # lesson pages (what you read)
│   ├── progress.md             # your live progress dashboard
│   ├── glossary.md
│   └── level1/module01/…       # one page per lesson
├── module01_intro/             # hands-on files (what you run)
│   └── lesson01_what_is_nextflow/
│       ├── make_data.sh
│       ├── naive_pipeline.sh
│       └── check_challenge.sh  # auto-checker: run it, the page updates
├── module02_environment/       # Module 2 hands-on files
├── progress/checks/            # results written by the checker scripts
├── tools/checklib.sh           # shared helper used by the checkers
├── includes/                   # animations + reference solutions (shown on the site)
└── hooks/course.py             # turns ```quiz blocks into interactive questions
```

**Run exercises and checkers inside the `moduleXX_*/lessonYY_*/` folders.** The lesson pages show those exact files, pulled in automatically, so what you read is always exactly what was tested.

## Optional: a static copy

```bash title="Terminal"
mkdocs build        # writes plain HTML to site/
open site/index.html
```

Later, when we cover Git, you can publish the site with `mkdocs gh-deploy` if you want it online.

## How your progress is saved

- **Answers on the lesson pages** are saved in your browser (local storage) for the address `http://127.0.0.1:8000`. Always open the course through `mkdocs serve` at that address so your answers stay together. Use **Export progress** on the [progress page](progress.md) to make a backup.
- **Checker scripts** (`bash check_….sh` in a lesson folder) save their results in `progress/checks/` in this project. While `mkdocs serve` is running, the site rebuilds and shows the new result automatically.
