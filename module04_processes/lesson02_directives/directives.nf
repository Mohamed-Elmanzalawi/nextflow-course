process FLAKY {
    tag "${sample}"
    cpus 1
    memory { 1.GB * task.attempt }
    errorStrategy 'retry'
    maxRetries 2

    input:
    val sample

    output:
    path "${sample}.txt"

    script:
    """
    echo "attempt ${task.attempt}: ${task.cpus} CPU, ${task.memory}"
    if [ ${task.attempt} -lt 2 ]; then
        echo "pretend we ran out of memory" >&2
        exit 137
    fi
    echo done > ${sample}.txt
    """
}

workflow {
    FLAKY(channel.of('s1', 's2'))
}
