params {
    input: Path = 'samplesheet.csv'
}

process COUNT_PAIRS {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.count.txt")

    script:
    """
    gzip -cd ${reads[0]} | awk 'END { print NR / 4 }' > ${meta.id}.count.txt
    """
}

workflow {
    samples = channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample, condition: row.condition, single_end: false]
            tuple(meta, [file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true)])
        }
    samples.view { meta, reads -> "in:  ${meta} ${reads.collect { f -> f.name }}" }

    counted = COUNT_PAIRS(samples)
        .map { meta, f -> tuple(meta + [read_pairs: f.text.trim().toInteger()], f) }
    counted.view { meta, _f -> "out: ${meta}" }
}
