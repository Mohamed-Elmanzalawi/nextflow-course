params {
    // Which FASTQ files to read (a glob pattern, so a String)
    reads: String = 'data/*.fastq'
    // Title written on the first line of the summary
    title: String = 'Read counts'
}

process COUNT_READS {
    input:
    path fq

    output:
    path "${fq.baseName}.count.tsv"

    script:
    """
    awk -v s=${fq.baseName} 'END { print s "\\t" NR / 4 }' ${fq} > ${fq.baseName}.count.tsv
    """
}

process SUMMARISE {
    input:
    path counts
    val title

    output:
    path 'summary.tsv'

    script:
    """
    echo '# ${title}' > summary.tsv
    cat ${counts} | sort >> summary.tsv
    """
}

workflow {
    main:
    reads_ch = channel.fromPath(params.reads)
    counts_ch = COUNT_READS(reads_ch)
    summary_ch = SUMMARISE(counts_ch.collect(), params.title)

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
        mode 'copy'
    }
}
