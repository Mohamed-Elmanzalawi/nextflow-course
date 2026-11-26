params {
    // Which FASTQ files to read (a glob pattern, so a String)
    reads: String = 'data/*.fastq'
}

process COUNT_READS {
    cache 'lenient'

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
    printf 'sample\treads\n' > summary.tsv
    cat ${counts} | sort >> summary.tsv
    """
}

workflow {
    main:
    reads_ch = channel.fromPath(params.reads)
    counts_ch = COUNT_READS(reads_ch)
    summary_ch = SUMMARISE(counts_ch.collect())

    publish:
    counts = counts_ch
    summary = summary_ch
}

output {
    counts {
        path 'counts'
    }
    summary {
        path '.'
    }
}
