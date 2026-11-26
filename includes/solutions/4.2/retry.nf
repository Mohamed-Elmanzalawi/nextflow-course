params {
    // Comma-separated sample names
    samples: String = 'alpha,beta,gamma'
}

process ASSEMBLE {
    tag "${sample}"
    memory { 1.GB * task.attempt }
    errorStrategy { task.exitStatus == 137 ? 'retry' : 'terminate' }
    maxRetries 3

    input:
    val sample

    output:
    path "${sample}.contigs.txt"

    script:
    """
    if [ "${sample}" = "corrupt" ]; then
        echo "ERROR: the input for ${sample} is corrupt" >&2
        exit 1
    fi
    if [ ${task.memory.toGiga()} -lt 3 ]; then
        echo "Out of memory with ${task.memory}" >&2
        exit 137
    fi
    echo "${sample} assembled with ${task.memory}" > ${sample}.contigs.txt
    """
}

workflow {
    ASSEMBLE(channel.fromList(params.samples.tokenize(',')))
}
