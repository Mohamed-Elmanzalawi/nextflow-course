params {
    reads: String = 'data/*.fastq'
    reads_per_chunk: Integer = 400
}

process SPLIT {
    input:
    path fq
    val reads_per_chunk

    output:
    path 'chunk_*.fastq', arity: '1..*', emit: chunks
    path "${fq.baseName}.small", optional: true, emit: small

    script:
    """
    awk -v n=${reads_per_chunk} -v base=${fq.baseName} '
        NR % (4 * n) == 1 { c++; out = sprintf("chunk_%s_%02d.fastq", base, c) }
        { print > out }
    ' ${fq}
    reads=\$(awk 'END { print NR / 4 }' ${fq})
    if [ \$reads -lt ${reads_per_chunk} ]; then
        echo "\$reads reads" > ${fq.baseName}.small
    fi
    """
}

process COUNT_CHUNK {
    input:
    path chunk

    output:
    path "${chunk.baseName}.count.tsv"

    script:
    """
    awk -v c=${chunk.baseName} 'END { print c "\\t" NR / 4 }' ${chunk} > ${chunk.baseName}.count.tsv
    """
}

process TOTAL {
    input:
    path counts

    output:
    path 'chunk_counts.tsv'

    script:
    """
    cat ${counts} | sort > chunk_counts.tsv
    """
}

workflow {
    split_out = SPLIT(channel.fromPath(params.reads), params.reads_per_chunk)
    counts = COUNT_CHUNK(split_out.chunks.flatten())
    TOTAL(counts.collect()).view()
    split_out.small.view { f -> "small sample: ${f.name}" }
}
