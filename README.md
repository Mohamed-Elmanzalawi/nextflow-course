# nextflow-course

An interactive, self-study course that goes from zero to building production [Nextflow](https://docs.seqera.io/nextflow/) pipelines for bioinformatics. It is built as an [MkDocs Material](https://squidfunk.github.io/mkdocs-material/) website in a "lab notebook" style.

Every lesson has:

- explanations and animated diagrams;
- runnable examples;
- questions you answer on the page (graded instantly, or by comparing with a model answer);
- checker scripts that test your hands-on work.

A dashboard tracks your progress automatically.

**Read it online:** <https://mohamed-elmanzalawi.github.io/nextflow-course/>

## Study with a local copy

The online site is fine for reading and answering questions. The hands-on parts need the repository on your own machine: the exercise files, and the checker scripts that report your results to the site.

```bash
git clone https://github.com/Mohamed-Elmanzalawi/nextflow-course.git
cd nextflow-course
conda create -n nf-course -c conda-forge python=3.12 mkdocs-material=9.8.2
conda activate nf-course
mkdocs serve          # then open http://127.0.0.1:8000/nextflow-course/
```

The `nf-course` environment is only for the website. You install Nextflow itself in Lesson 2.2.

Your answers are saved in your browser for each site address, so progress made on the local site does not appear on the online site, and vice versa. Use **Export** and **Import** on the Progress page to move it.

## Publishing

Every push to `main` runs `.github/workflows/deploy.yml`. It builds the site with `mkdocs gh-deploy --strict` and pushes it to the `gh-pages` branch, which GitHub Pages serves. Before pushing, check that `mkdocs build --strict` passes locally.

## Layout

| Path | Contents |
|---|---|
| `docs/` | Lesson pages, the progress dashboard, the glossary, and the theme |
| `moduleXX_*/lessonYY_*/` | Hands-on files for each lesson, including its `check_*.sh` checker scripts |
| `includes/` | Animated diagrams and reference solutions shown on the site |
| `hooks/`, `tools/` | The interactive-question system, the checker helpers, and the animation generator |
| `progress/checks/` | Results written by the checker scripts |
| `.github/workflows/` | The workflow that publishes the site to GitHub Pages |

The course is based on the [Nextflow training](https://training.nextflow.io/) material and the EMBL-EBI [Introduction to Nextflow](https://www.ebi.ac.uk/training/online/courses/nextflow/introduction-to-nextflow/) course.

Course designed by Mohamed Elmanzalawi.
