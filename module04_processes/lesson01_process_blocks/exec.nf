process SQUARE {
    input:
    val x

    output:
    val y

    exec:
    y = x * x
}

workflow {
    SQUARE(channel.of(1, 2, 3)).view()
}
