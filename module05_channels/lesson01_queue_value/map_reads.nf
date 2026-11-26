process MAP_READS {
    tag "${reads.simpleName}"

    input:
    path reads
    path reference

    output:
    stdout

    script:
    """
    echo "${reads.simpleName} mapped against ${reference}"
    """
}

workflow {
    reads_ch = channel.fromPath('data/*_R1.fastq.gz')
    ref_ch = channel.fromPath('ref.fa')
    MAP_READS(reads_ch, ref_ch).view { s -> s.trim() }
}
