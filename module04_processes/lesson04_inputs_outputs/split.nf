process SPLIT {
    input:
    path fq
    val reads_per_chunk

    output:
    path 'chunk_*.fastq', emit: chunks
    path 'n_chunks.txt', emit: n
    path 'warning.txt', optional: true, emit: warning

    script:
    """
    awk -v n=${reads_per_chunk} -v base=${fq.baseName} '
        NR % (4 * n) == 1 { c++; out = sprintf("chunk_%s_%02d.fastq", base, c) }
        { print > out }
    ' ${fq}
    ls chunk_*.fastq | wc -l | tr -d ' ' > n_chunks.txt
    if [ \$(cat n_chunks.txt) -gt 4 ]; then
        echo "many chunks" > warning.txt
    fi
    """
}

workflow {
    out = SPLIT(channel.fromPath('data/*.fastq'), 400)
    out.chunks.view { files -> "chunks:  ${files.collect { f -> f.name }}" }
    out.warning.view { f -> "warning: ${f}" }
}
