process FIRST_READ {
    input:
    path fq

    output:
    path 'first_read.txt'

    script:
    """
    gzip -cd ${fq} | head -n 4 > first_read.txt
    """
}

workflow {
    FIRST_READ(channel.fromPath('data/sample1.fastq'))
}
