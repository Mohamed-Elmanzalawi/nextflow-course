// Lesson 4.2 challenge: make ASSEMBLE survive running out of memory.
// Run:  nextflow run retry.nf      Check:  bash check_retry.sh

params {
    // Comma-separated sample names
    samples: String = 'alpha,beta,gamma'
}

process ASSEMBLE {
    // TODO 1: label each task with its sample name
    // TODO 2: start with 1 GB and add 1 GB on every new attempt
    // TODO 3: retry when the task runs out of memory (exit status 137), at most 3 retries;
    //         stop the pipeline on any other error
    memory 1.GB

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
