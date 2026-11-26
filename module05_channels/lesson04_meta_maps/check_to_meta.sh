#!/usr/bin/env bash
# Lesson 5.4 challenge checker: runs your to_meta.nf on a new samplesheet (with a batch column)
# and checks that the processes use the meta-map pattern.
# Usage: bash check_to_meta.sh [path/to/to_meta.nf]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../tools/checklib.sh"
source "$HERE/../../tools/nflib.sh"
ID="5.4-challenge"
SCRIPT="${1:-$HERE/to_meta.nf}"

echo "Checking $SCRIPT"
if ! nf_have; then fail "Nextflow is installed" "install it first (Lesson 2.2)"; finish "$ID"; exit 1; fi
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$SCRIPT" "$TMP/to_meta.nf" 2>/dev/null || { fail "to_meta.nf exists" "not found: $SCRIPT"; finish "$ID"; exit 1; }
bash "$HERE/../fresh_reads.sh" "$TMP/reads" mouse1=cov_b ctrl7=hsa_rna
printf 'sample,condition,batch,fastq_1,fastq_2\nmouse1,treated,run42,reads/mouse1_R1.fastq.gz,reads/mouse1_R2.fastq.gz\nctrl7,untreated,run43,reads/ctrl7_R1.fastq.gz,reads/ctrl7_R2.fastq.gz\n' > "$TMP/new.csv"
printf "trace {\n    fields = 'name,tag,status,exit'\n}\n" > "$TMP/trace.config"

if (cd "$TMP" && nextflow lint to_meta.nf > lint.log 2>&1); then
    pass "to_meta.nf passes 'nextflow lint'"
else
    fail "to_meta.nf passes 'nextflow lint'" "$(grep -m1 -E '^Error' "$TMP/lint.log")"
fi

# Structure: inputs use tuple val(meta), and no longer carry sample/condition by position
metas=$(grep -cE '^[[:space:]]*tuple val\(meta\)' "$TMP/to_meta.nf")
positional=$(grep -cE 'val\((sample|condition|condition_again)\)' "$TMP/to_meta.nf")
if [[ "$metas" -ge 5 && "$positional" == 0 ]]; then
    pass "Processes take and emit 'tuple val(meta), …'" "$metas meta tuples, no positional sample/condition"
else
    fail "Processes take and emit 'tuple val(meta), …'" "tuple val(meta) lines: $metas (expect ≥ 5), positional val(sample/condition): $positional"
fi

if nf_run "$TMP" trace.tsv to_meta.nf -c trace.config --input new.csv; then
    pass "Runs on a new samplesheet"
else
    fail "Runs on a new samplesheet" "$(nf_error "$TMP")"
fi

tags=$(awk -F'\t' 'NR > 1 && $1 ~ /^COUNT_READS/ && $3 == "COMPLETED" { print $2 }' "$TMP/trace.tsv" 2>/dev/null | sort | tr '\n' ' ')
if [[ "$tags" == "ctrl7 mouse1 " ]]; then
    pass "Tasks are tagged with meta.id"
else
    fail "Tasks are tagged with meta.id" "COUNT_READS tags: ${tags:-none}"
fi

gc() { gzip -cd "$@" | awk 'NR % 4 == 2 { b += length($0); gc += gsub(/[GC]/, "") } END { printf "%.1f", 100 * gc / b }'; }
want=$(printf 'ctrl7\tuntreated\trun43\t4159\t%s\nmouse1\ttreated\trun42\t100\t%s' \
    "$(gc "$TMP"/reads/ctrl7_R1.fastq.gz "$TMP"/reads/ctrl7_R2.fastq.gz)" \
    "$(gc "$TMP"/reads/mouse1_R1.fastq.gz "$TMP"/reads/mouse1_R2.fastq.gz)")
got=$(cat "$(find "$TMP/work" -name qc_table.tsv -type f 2>/dev/null | head -n 1)" 2>/dev/null)
if [[ "$got" == "$want" ]]; then
    pass "qc_table.tsv: id, condition, batch, reads, GC% for every sample"
else
    fail "qc_table.tsv: id, condition, batch, reads, GC% for every sample" "got: $(tr '\t\n' ' ;' <<< "$got")"
fi
finish "$ID"
