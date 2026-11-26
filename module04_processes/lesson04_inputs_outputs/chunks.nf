// Lesson 4.4 challenge: complete the TODOs in SPLIT's output block and in the workflow.
// Run:  nextflow run chunks.nf      Check:  bash check_chunks.sh

params {
    reads: String = 'data/*.fastq'
    reads_per_chunk: Integer = 400
}

process SPLIT {
    input:
    path fq
    val reads_per_chunk

    output:
    // TODO 1: name this output 'chunks', and make it ALWAYS a list (even for one chunk)
    path 'chunk_*.fastq'
    // TODO 2: add the <sample>.small file (only small samples make one), named 'small'

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
    // TODO 3: run COUNT_CHUNK once per chunk file (hint: the chunks channel delivers LISTS)
    // TODO 4: give all the counts to TOTAL at once, and view() its output
    // TODO 5: view() the small-sample files
}
