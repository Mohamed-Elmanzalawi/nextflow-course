params {
    input: Path = 'samplesheet.csv'
}

workflow {
    channel.of('cov_a', 'cov_b').view { v -> "of:        ${v}" }
    channel.fromList(['x', 'y']).view { v -> "fromList:  ${v}" }
    channel.fromPath('data/*_R1.fastq.gz').view { f -> "fromPath:  ${f.name}" }
    channel.fromFilePairs('data/*_R{1,2}.fastq.gz').view { id, files -> "pairs:     ${id} ${files.collect { f -> f.name }}" }

    channel.fromPath(params.input)
        .splitCsv(header: true)
        .view { row -> "csv row:   ${row}" }

    channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample, file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true)) }
        .view { id, r1, r2 -> "tuple:     ${id} ${r1.name} ${r2.name}" }
}
