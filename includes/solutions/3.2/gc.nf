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

process GC_CONTENT {
    input:
    path fq

    output:
    path "${fq.baseName}.gc.tsv"

    script:
    """
    awk -v s=${fq.baseName} '
        NR % 4 == 2 { bases += length(\$0); gc += gsub(/[GC]/, "") }
        END { printf "%s\\t%.2f\\n", s, 100 * gc / bases }
    ' ${fq} > ${fq.baseName}.gc.tsv
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

process GC_SUMMARY {
    input:
    path gc_files

    output:
    path 'gc_summary.tsv'

    script:
    """
    cat ${gc_files} | sort > gc_summary.tsv
    """
}

workflow {
    reads_ch = channel.fromPath('data/*.fastq')

    counts_ch = COUNT_READS(reads_ch)
    gc_ch = GC_CONTENT(reads_ch)

    SUMMARISE(counts_ch.collect()).view()
    GC_SUMMARY(gc_ch.collect()).view()
}
