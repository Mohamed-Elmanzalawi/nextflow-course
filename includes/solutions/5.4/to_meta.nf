params {
    // CSV with columns sample,condition,batch,fastq_1,fastq_2
    input: Path = 'samplesheet.csv'
}

process COUNT_READS {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.reads.txt")

    script:
    """
    gzip -cd ${reads[0]} | awk 'END { print NR / 4 }' > ${meta.id}.reads.txt
    """
}

process GC_CONTENT {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.gc.txt")

    script:
    """
    gzip -cd ${reads} | awk 'NR % 4 == 2 { b += length(\$0); gc += gsub(/[GC]/, "") }
        END { printf "%.1f\\n", 100 * gc / b }' > ${meta.id}.gc.txt
    """
}

process ROW {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads_txt), path(gc_txt)

    output:
    path "${meta.id}.row.tsv"

    script:
    """
    printf '%s\\t%s\\t%s\\t%s\\t%s\\n' ${meta.id} ${meta.condition} ${meta.batch} \$(cat ${reads_txt}) \$(cat ${gc_txt}) > ${meta.id}.row.tsv
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
            def meta = [id: row.sample, condition: row.condition, batch: row.batch, single_end: false]
            tuple(meta, [file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true)])
        }

    counts = COUNT_READS(samples)
    gcs = GC_CONTENT(samples)
    REPORT(ROW(counts.join(gcs)).collect()).view()
}
