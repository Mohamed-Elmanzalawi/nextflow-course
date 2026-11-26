// Lesson 4.3 challenge: this pipeline has three bugs.
// Find each one from the error report and the task folders, fix it, and resume.

params {
    reads: String = 'data/*.fastq.gz'
}

process READ_STATS {
    input:
    path fq

    output:
    path "${fq.simpleName}.stats.tsv"

    script:
    """
    gzip -cd ${fq} | awk -v s=${fq.simpleName} 'END { print s "\\t" NR / 4 }' > ${fq.simpleName}.tsv
    """
}

process MEAN_LENGTH {
    input:
    path fq

    output:
    path "${fq.simpleName}.length.tsv"

    script:
    """
    bash scripts/mean_length.sh ${fq} > ${fq.simpleName}.length.tsv
    """
}

process REPORT {
    input:
    path stats
    path lengths

    output:
    path 'qc_report.tsv'

    script:
    """
    cat ${stats} | sort > reads.tsv
    cat ${lengths} | sort > lengths.tsv
    join -t \$'\\t' reads.tsv lengths.tsv > qc_report.tsv
    """
}

workflow {
    main:
    reads_ch = channel.fromPath(params.reads)
    stats_ch = READ_STATS(reads_ch)
    length_ch = MEAN_LENGTH(reads_ch)
    report_ch = REPORT(stats_ch.collect(), length_ch.collect())

    publish:
    report = report_ch
}

output {
    report {
        path '.'
        mode 'copy'
    }
}
