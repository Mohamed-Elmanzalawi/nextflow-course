#!/usr/bin/env bash
# Download small, real paired-end FASTQ files from nf-core's public test datasets
# (pinned to one commit, so they never change) into ./data, and check their SHA-256.
#   cov_a / cov_b : SARS-CoV-2 Illumina reads, 100 pairs each, 150 bp
#   hsa_rna       : human RNA-seq reads, 4,159 pairs
# Usage: bash get_data.sh [out_dir]
set -euo pipefail
out=${1:-data}
base="https://raw.githubusercontent.com/nf-core/test-datasets/02550aeca1f285f49ed70f533738f5e12e841ba8/data/genomics"
files=(
  "cov_a_R1.fastq.gz   sarscov2/illumina/fastq/test_1.fastq.gz            0515ba304cb1bf7abcdd9c156b6affad7e580273f983dfed2e8fe2d918e800ff"
  "cov_a_R2.fastq.gz   sarscov2/illumina/fastq/test_2.fastq.gz            0080f40cab58c7e7b85443e37de22775e3ed6b7afdef9a3271ac3147576f3027"
  "cov_b_R1.fastq.gz   sarscov2/illumina/fastq/test2_1.fastq.gz           e4fae112b41bcbb2f8e2a30246f004df7070e396a13080242c0b22d7278f8db3"
  "cov_b_R2.fastq.gz   sarscov2/illumina/fastq/test2_2.fastq.gz           d420eeac72d87df96662bb5bba6fc4fcd36efa413d74f2bb117f706121aae4df"
  "hsa_rna_R1.fastq.gz homo_sapiens/illumina/fastq/test_rnaseq_1.fastq.gz 9119c9e68d7a326164728f645c6e90b7317ea3ad8a1c509926533560110a1c1a"
  "hsa_rna_R2.fastq.gz homo_sapiens/illumina/fastq/test_rnaseq_2.fastq.gz fe2130d59d71d2c3e8a1dfee2a8407a5f4449bdc4e779da878396b0b742d3d37"
)
mkdir -p "$out"
for line in "${files[@]}"; do
    read -r name path sum <<< "$line"
    if [[ -f "${out}/${name}" ]] && [[ "$(shasum -a 256 "${out}/${name}" | cut -c1-64)" == "$sum" ]]; then
        echo "ok (already here)  ${out}/${name}"; continue
    fi
    curl -sfL -o "${out}/${name}" "${base}/${path}"
    if [[ "$(shasum -a 256 "${out}/${name}" | cut -c1-64)" != "$sum" ]]; then
        echo "ERROR: checksum mismatch for ${name}" >&2; exit 1
    fi
    echo "downloaded         ${out}/${name}"
done
