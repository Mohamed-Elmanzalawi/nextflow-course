// Lesson 5.2 challenge: build the samples channel from the samplesheet.
// Run:  nextflow run read_sheet.nf      Check:  bash check_read_sheet.sh

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
    // TODO: read params.input, split it into rows (one per sample) and turn each row into
    //       tuple(sample, R1 file, R2 file). Every file must be checked: a missing file
    //       must stop the run with an error that names it.
    samples = channel.empty()

    REPORT(COUNT_PAIRS(samples).collect()).view()
}
