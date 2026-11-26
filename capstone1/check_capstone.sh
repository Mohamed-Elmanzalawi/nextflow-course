#!/usr/bin/env bash
# Capstone 1 checker: runs your main.nf on a NEW samplesheet (other sample names), twice.
# Usage: bash check_capstone.sh [path/to/main.nf]
#   Uses -profile docker when Docker is running, otherwise -profile conda.
#   Force one with: CAPSTONE_PROFILE=conda bash check_capstone.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../tools/checklib.sh"
source "$HERE/../tools/nflib.sh"
ID="capstone1"
SCRIPT="${1:-$HERE/main.nf}"

echo "Checking $SCRIPT"
if ! nf_have; then
    fail "Nextflow is installed" "install it first (Lesson 2.2)"
    finish "$ID"; exit 1
fi
if [[ -n "${CAPSTONE_PROFILE:-}" ]]; then PROFILE=$CAPSTONE_PROFILE
elif docker info > /dev/null 2>&1; then PROFILE=docker
else PROFILE=conda; fi
echo "Using -profile $PROFILE (this can take a few minutes the first time)"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$SCRIPT" "$TMP/main.nf" 2>/dev/null || { fail "main.nf exists" "not found: $SCRIPT"; finish "$ID"; exit 1; }
cp "$HERE/nextflow.config" "$TMP/"
printf "trace {\n    fields = 'name,tag,status,exit'\n}\n" > "$TMP/trace.config"

# Fresh samples with new names: pt01 = SARS-CoV-2 pair, pt02 = human RNA-seq pair
data="$HERE/data"
if [[ ! -f "$data/cov_a_R1.fastq.gz" || ! -f "$data/hsa_rna_R2.fastq.gz" ]]; then
    data="$TMP/download"; bash "$HERE/../module05_channels/get_data.sh" "$data" > /dev/null || true
fi
mkdir -p "$TMP/reads"
for pair in "pt01 cov_a" "pt02 hsa_rna"; do
    read -r new old <<< "$pair"
    cp "$data/${old}_R1.fastq.gz" "$TMP/reads/${new}_R1.fastq.gz" 2>/dev/null
    cp "$data/${old}_R2.fastq.gz" "$TMP/reads/${new}_R2.fastq.gz" 2>/dev/null
done
printf 'sample,fastq_1,fastq_2\npt01,reads/pt01_R1.fastq.gz,reads/pt01_R2.fastq.gz\npt02,reads/pt02_R1.fastq.gz,reads/pt02_R2.fastq.gz\n' > "$TMP/new_samples.csv"

if (cd "$TMP" && nextflow lint main.nf > lint.log 2>&1); then
    pass "main.nf passes 'nextflow lint'"
else
    fail "main.nf passes 'nextflow lint'" "$(grep -m1 -E '^Error' "$TMP/lint.log")"
fi

# Run 1
if nf_run "$TMP" trace1.tsv main.nf -profile "$PROFILE" -c trace.config --input new_samples.csv -output-dir out; then
    pass "Runs on a new samplesheet (-profile $PROFILE)"
else
    fail "Runs on a new samplesheet (-profile $PROFILE)" "$(nf_error "$TMP")"
fi

tags=$(awk -F'\t' 'NR > 1 && $1 ~ /^FASTQC/ && $3 == "COMPLETED" { print $2 }' "$TMP/trace1.tsv" 2>/dev/null | sort | tr '\n' ' ')
if [[ "$tags" == "pt01 pt02 " ]]; then
    pass "FASTQC runs once per sample, tagged with the sample name"
else
    fail "FASTQC runs once per sample, tagged with the sample name" "completed FASTQC tags: ${tags:-none}"
fi

html=$(find "$TMP/out/fastqc" -name '*_fastqc.html' -type f 2>/dev/null | xargs -n1 basename 2>/dev/null | sort | tr '\n' ' ')
if [[ "$html" == "pt01_R1_fastqc.html pt01_R2_fastqc.html pt02_R1_fastqc.html pt02_R2_fastqc.html " ]]; then
    pass "4 FastQC HTML reports published in fastqc/ (real files)"
else
    fail "4 FastQC HTML reports published in fastqc/ (real files)" "found: ${html:-none}"
fi

mqc=$(find "$TMP/out" -name multiqc_fastqc.txt -type f 2>/dev/null | head -n 1)
samples=$(cut -f1 "${mqc:-/dev/null}" 2>/dev/null | tail -n +2 | sort | tr '\n' ' ')
if [[ -f "$TMP/out/multiqc_report.html" && "$samples" == "pt01_R1 pt01_R2 pt02_R1 pt02_R2 " ]]; then
    pass "One MultiQC report covers all 4 FASTQ files"
else
    fail "One MultiQC report covers all 4 FASTQ files" \
        "report: $([[ -f "$TMP/out/multiqc_report.html" ]] && echo yes || echo no); samples in its data: ${samples:-none}"
fi

# Run 2: -resume must take everything from the cache
nf_run "$TMP" trace2.tsv main.nf -profile "$PROFILE" -c trace.config --input new_samples.csv -output-dir out -resume
cached=$(awk -F'\t' 'NR > 1 && $3 == "CACHED"' "$TMP/trace2.tsv" 2>/dev/null | wc -l | tr -d ' ')
ran=$(awk -F'\t' 'NR > 1 && $3 == "COMPLETED"' "$TMP/trace2.tsv" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$cached" -ge 3 && "$ran" == 0 ]]; then
    pass "-resume takes every task from the cache" "$cached cached"
else
    fail "-resume takes every task from the cache" "cached=$cached, ran again=$ran"
fi

finish "$ID" "profile: $PROFILE"
