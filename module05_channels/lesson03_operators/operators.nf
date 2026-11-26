workflow {
    numbers = channel.of(1, 2, 3, 4, 5)

    numbers.map { n -> n * 10 }.view { v -> "map:        ${v}" }
    numbers.filter { n -> n % 2 == 1 }.view { v -> "filter:     ${v}" }
    numbers.collect().view { v -> "collect:    ${v}" }
    channel.of([1, 2], [3]).flatten().view { v -> "flatten:    ${v}" }
    channel.of('a', 'b').mix(channel.of('z')).view { v -> "mix:        ${v}" }

    reads = channel.of(['cov_a', 100], ['cov_b', 100])
    gc = channel.of(['cov_b', 37.6], ['cov_a', 38.2])
    reads.join(gc).view { v -> "join:       ${v}" }

    lanes = channel.of(['s1', 'L001.fq'], ['s2', 'L001.fq'], ['s1', 'L002.fq'])
    lanes.groupTuple().view { v -> "groupTuple: ${v}" }

    samples = channel.of('cov_a', 'cov_b')
    refs = channel.of('MN908947', 'GRCh38')
    samples.combine(refs).view { v -> "combine:    ${v}" }

    numbers.sum().view { v -> "sum:        ${v}" }
    numbers.count().view { v -> "count:      ${v}" }
    channel.of(1..3).view { v -> "range:      ${v}" }
}
