process FASTQC_VERSION {
    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'
    conda 'bioconda::fastqc=0.12.1'

    output:
    stdout

    script:
    """
    fastqc --version
    """
}

workflow {
    FASTQC_VERSION().view { "Inside the task: " + it.trim() }
}
