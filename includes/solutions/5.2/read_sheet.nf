params {
    // CSV with columns sample,fastq_1,fastq_2
    input: Path = 'samplesheet.csv'
}

process COUNT_PAIRS {
    tag "${sample}"

    input:
    tuple val(sample), path(r1), path(r2)

    output:
    path "${sample}.pairs.tsv"

    script:
    """
    n1=\$(gzip -cd ${r1} | awk 'END { print NR / 4 }')
    n2=\$(gzip -cd ${r2} | awk 'END { print NR / 4 }')
    printf '%s\\t%s\\t%s\\n' ${sample} \$n1 \$n2 > ${sample}.pairs.tsv
    """
}

process REPORT {
    input:
    path tables

    output:
    path 'pairs_report.tsv'

    script:
    """
    cat ${tables} | sort > pairs_report.tsv
    """
}

workflow {
    samples = channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            tuple(row.sample, file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true))
        }

    REPORT(COUNT_PAIRS(samples).collect()).view()
}
