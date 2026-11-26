process LENGTH_STATS {
    input:
    path fq
    val min_len

    output:
    path "${fq.baseName}.lengths.txt"

    script:
    """
    sleep 3    # pretend this is a slow tool
    awk -v min=${min_len} '
        NR % 4 == 2 { reads++; if (length(\$0) >= min) long++ }
        END { print "reads:", reads, "long enough:", long }
    ' ${fq} > ${fq.baseName}.lengths.txt
    echo "bash version: \$BASH_VERSION" >> ${fq.baseName}.lengths.txt
    """

    stub:
    """
    touch ${fq.baseName}.lengths.txt
    """
}

workflow {
    LENGTH_STATS(channel.fromPath('data/*.fastq'), 50).view { f -> f.name }
}
