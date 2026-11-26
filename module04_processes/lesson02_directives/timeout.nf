process SLOW {
    time '2s'

    script:
    """
    sleep 20
    """
}

workflow {
    SLOW()
}
