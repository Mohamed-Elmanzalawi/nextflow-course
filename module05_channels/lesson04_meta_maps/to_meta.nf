// Lesson 5.4 challenge: this pipeline works, but every process carries `sample` and
// `condition` around by position. Rewrite it with the meta-map pattern.
// Run:  nextflow run to_meta.nf      Check:  bash check_to_meta.sh

params {
    // CSV with columns sample,condition,batch,fastq_1,fastq_2
    input: Path = 'samplesheet.csv'
}

process COUNT_READS {
    tag "${sample}"

    input:
    tuple val(sample), val(condition), path(r1), path(r2)

    output:
    tuple val(sample), val(condition), path("${sample}.reads.txt")

    script:
    """
    gzip -cd ${r1} | awk 'END { print NR / 4 }' > ${sample}.reads.txt
    """
}

process GC_CONTENT {
    tag "${sample}"

    input:
    tuple val(sample), val(condition), path(r1), path(r2)

    output:
    tuple val(sample), val(condition), path("${sample}.gc.txt")

    script:
    """
    gzip -cd ${r1} ${r2} | awk 'NR % 4 == 2 { b += length(\$0); gc += gsub(/[GC]/, "") }
        END { printf "%.1f\\n", 100 * gc / b }' > ${sample}.gc.txt
    """
}

process ROW {
    tag "${sample}"

    input:
    tuple val(sample), val(condition), path(reads_txt), val(condition_again), path(gc_txt)

    output:
    path "${sample}.row.tsv"

    script:
    """
    printf '%s\\t%s\\t%s\\t%s\\n' ${sample} ${condition} \$(cat ${reads_txt}) \$(cat ${gc_txt}) > ${sample}.row.tsv
    """
}

process REPORT {
    input:
    path rows

    output:
    path 'qc_table.tsv'

    script:
    """
    cat ${rows} | sort > qc_table.tsv
    """
}

workflow {
    samples = channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            tuple(row.sample, row.condition, file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true))
        }

    counts = COUNT_READS(samples)
    gcs = GC_CONTENT(samples)
    REPORT(ROW(counts.join(gcs)).collect()).view()
}
