// Lesson 3.1 challenge: greet three people.
// Fill in the TODOs, then run:  bash check_greet.sh

process GREET {
    // TODO: an input that receives one name

    // TODO: an output file called greeting_<name>.txt

    script:
    """
    # TODO: write "Hello, <name>!" into greeting_<name>.txt
    """
}

workflow {
    // TODO: a channel with Ada, Rosalind and Barbara, given to GREET
}
