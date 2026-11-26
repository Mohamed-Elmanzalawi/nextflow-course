process PAIR {
    input:
    val number
    val letter

    output:
    stdout

    script:
    """
    echo "${number} + ${letter}"
    """
}

workflow {
    numbers = channel.of(1, 2, 3)
    letters = channel.of('a', 'b')
    PAIR(numbers, letters).view { s -> s.trim() }
}
