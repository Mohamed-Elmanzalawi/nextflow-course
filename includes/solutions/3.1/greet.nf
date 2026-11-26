process GREET {
    input:
    val name

    output:
    path "greeting_${name}.txt"

    script:
    """
    echo 'Hello, ${name}!' > greeting_${name}.txt
    """
}

workflow {
    names = channel.of('Ada', 'Rosalind', 'Barbara')
    GREET(names)
}
