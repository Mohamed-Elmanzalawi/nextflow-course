process SAY_HELLO {
    input:
    val greeting

    output:
    path "${greeting}.txt"

    script:
    """
    echo '${greeting} from Nextflow!' > ${greeting}.txt
    """
}

workflow {
    greetings = channel.of('Hello', 'Bonjour', 'Hola')
    SAY_HELLO(greetings)
}
