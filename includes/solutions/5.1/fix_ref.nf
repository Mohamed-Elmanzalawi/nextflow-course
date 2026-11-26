params {
    reads: String = 'data/*_R1.fastq.gz'
    reference: Path = 'ref.fa'
    adapter: String = 'AGATCGGAAGAGC'
}

process TRIM_AND_MAP {
    tag "${reads.simpleName}"

    input:
    path reads
    path reference
    val adapter

    output:
    path "${reads.simpleName}.log"

    script:
    """
    n=\$(gzip -cd ${reads} | awk 'END { print NR / 4 }')
    echo "${reads.simpleName}: \$n reads, adapter ${adapter}, reference ${reference}" > ${reads.simpleName}.log
    """
}

process SUMMARY {
    input:
    path logs

    output:
    path 'summary.txt'

    script:
    """
    cat ${logs} | sort > summary.txt
    """
}

workflow {
    reads_ch = channel.fromPath(params.reads)
    ref_ch = channel.value(params.reference)     // a value channel: read by every task
    adapter_ch = channel.value(params.adapter)

    logs = TRIM_AND_MAP(reads_ch, ref_ch, adapter_ch)
    SUMMARY(logs.collect()).view()
}
