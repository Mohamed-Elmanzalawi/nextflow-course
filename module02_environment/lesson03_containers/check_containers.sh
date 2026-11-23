#!/usr/bin/env bash
# Auto-checker for Lesson 2.3: Docker, conda and Nextflow can all provide FastQC.
# Usage: bash check_containers.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../../tools/checklib.sh"
ID="2.3-containers"
IMAGE="quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0"
ENV="${FASTQC_ENV:-nf-fastqc}"
CFG="${NF_CONFIG:-$HERE/nextflow.config}"
CONDA="${CONDA_EXE:-conda}"
if [[ "$ENV" == */* ]]; then ENVFLAG=(-p "$ENV"); else ENVFLAG=(-n "$ENV"); fi

echo "Checking Docker, conda and Nextflow (takes ~1 minute)…"

if docker info > /dev/null 2>&1; then
    pass "Docker is running"
    if out=$(perl -e 'alarm 300; exec @ARGV' docker run --rm --platform linux/amd64 "$IMAGE" fastqc --version 2>&1) && [[ "$out" == *"FastQC v0.12.1"* ]]; then
        pass "FastQC runs in a BioContainers image" "$out"
    else
        fail "FastQC runs in a BioContainers image" "$(tail -n 1 <<< "$out")"
    fi
else
    fail "Docker is running" "start Docker Desktop and try again"
    fail "FastQC runs in a BioContainers image" "needs Docker"
fi

if out=$("$CONDA" run "${ENVFLAG[@]}" fastqc --version 2>&1) && [[ "$out" == *"FastQC v0.12.1"* ]]; then
    pass "Conda environment '$ENV' provides FastQC 0.12.1"
else
    fail "Conda environment '$ENV' provides FastQC 0.12.1" "create it with: conda create -n nf-fastqc -c conda-forge -c bioconda fastqc=0.12.1"
fi

if command -v nextflow > /dev/null 2>&1; then
    TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
    cp "$HERE/main.nf" "$TMP/" && cp "$CFG" "$TMP/nextflow.config"
    for prof in docker conda; do
        if (cd "$TMP" && perl -e 'alarm 600; exec @ARGV' nextflow run main.nf -profile "$prof" -ansi-log false > "$prof.log" 2>&1) \
           && grep -q 'Inside the task: FastQC v0.12.1' "$TMP/$prof.log"; then
            pass "Nextflow runs FastQC with -profile $prof"
        else
            fail "Nextflow runs FastQC with -profile $prof" "$(grep -m1 -E 'ERROR|Caused by' "$TMP/$prof.log" 2>/dev/null)"
        fi
    done
    flat=$(cd "$TMP" && nextflow config -flat -profile apptainer . 2>&1)
    if grep -q '^apptainer.enabled = true' <<< "$flat" && grep -q '^apptainer.autoMounts = true' <<< "$flat"; then
        pass "Challenge: 'apptainer' profile defined" "enabled + autoMounts"
    else
        fail "Challenge: 'apptainer' profile defined" "$(head -n 1 <<< "$flat")"
    fi
else
    fail "Nextflow runs FastQC with -profile docker" "install Nextflow first (Lesson 2.2)"
    fail "Nextflow runs FastQC with -profile conda" "install Nextflow first (Lesson 2.2)"
    fail "Challenge: 'apptainer' profile defined" "install Nextflow first (Lesson 2.2)"
fi

finish "$ID" "Docker $(docker version --format '{{.Server.Version}}' 2>/dev/null || echo 'n/a')"
