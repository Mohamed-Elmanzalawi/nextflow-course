// The same pipeline, published the older way with the publishDir directive.
// You'll see this style in nf-core pipelines and older tutorials.
params.reads = 'data/*.fastq'
params.outdir = 'results'

process COUNT_READS {
    publishDir "${params.outdir}/counts", mode: 'copy'

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
    publishDir params.outdir, mode: 'copy'

    input:
    path counts

    output:
    path 'summary.tsv'

    script:
    """
    cat ${counts} | sort > summary.tsv
    """
}

workflow {
    reads_ch = channel.fromPath(params.reads)
    counts_ch = COUNT_READS(reads_ch)
    SUMMARISE(counts_ch.collect())
}
