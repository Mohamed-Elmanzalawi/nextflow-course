# nextflow-course

An interactive, self-study course that goes from zero to building production [Nextflow](https://docs.seqera.io/nextflow/) pipelines for bioinformatics. It is built as an [MkDocs Material](https://squidfunk.github.io/mkdocs-material/) website in a "lab notebook" style.

Every lesson has:

- explanations and animated diagrams;
- runnable examples;
- questions you answer on the page (graded instantly, or by comparing with a model answer);
- checker scripts that test your hands-on work.

A dashboard tracks your progress automatically.

## Run the course locally

```bash
conda create -n nf-course -c conda-forge python=3.12 mkdocs-material
conda activate nf-course
mkdocs serve          # then open http://127.0.0.1:8000
```

## Layout

| Path | Contents |
|---|---|
| `docs/` | Lesson pages, the progress dashboard, the glossary, and the theme |
| `moduleXX_*/lessonYY_*/` | Hands-on files for each lesson, including its `check_*.sh` checker scripts |
| `includes/` | Animated diagrams and reference solutions shown on the site |
| `hooks/`, `tools/` | The interactive-question system, the checker helpers, and the animation generator |
| `progress/checks/` | Results written by the checker scripts |

The course is based on the [Nextflow training](https://training.nextflow.io/) material and the EMBL-EBI [Introduction to Nextflow](https://www.ebi.ac.uk/training/online/courses/nextflow/introduction-to-nextflow/) course.

Course designed by Mohamed Elmanzalawi.
