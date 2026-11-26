process AS_VAL {
    input:
    val fq

    output:
    stdout

    script:
    """
    ls -l ${fq} | awk '{ print \$1, \$NF }'
    """
}

process AS_PATH {
    input:
    path fq

    output:
    stdout

    script:
    """
    ls -l ${fq} | awk '{ print \$1, \$(NF - 2), \$(NF - 1), \$NF }'
    """
}

workflow {
    f = channel.fromPath('data/sample1.fastq')
    AS_VAL(f).view { s -> "val : ${s.trim()}" }
    AS_PATH(f).view { s -> "path: ${s.trim()}" }
}
