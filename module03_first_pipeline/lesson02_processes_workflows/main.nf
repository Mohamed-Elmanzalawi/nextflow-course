process COUNT_READS {
    input:
    path fq

    output:
    path "${fq.baseName}.count.tsv"

    script:
    """
    sleep 2
    awk -v s=${fq.baseName} 'END { print s "\\t" NR / 4 }' ${fq} > ${fq.baseName}.count.tsv
    """
}

process SUMMARISE {
    input:
    path counts

    output:
    path 'summary.tsv'

    script:
    """
    cat ${counts} > summary.tsv
    """
}

workflow {
    reads_ch = channel.fromPath('data/*.fastq')
    counts_ch = COUNT_READS(reads_ch)
    summary_ch = SUMMARISE(counts_ch.collect())
    summary_ch.view()
}
