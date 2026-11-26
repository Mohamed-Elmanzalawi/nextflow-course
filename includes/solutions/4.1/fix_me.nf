process GC_REPORT {
    input:
    path fq

    output:
    path "${fq.baseName}.report.txt"

    script:
    """
    sleep 3    # pretend this is a slow tool
    reads=\$(awk 'END { print NR / 4 }' ${fq})
    gc=\$(awk 'NR % 4 == 2' ${fq} | tr -cd 'GC' | wc -c | tr -d ' ')
    echo "sample: ${fq.baseName}" > ${fq.baseName}.report.txt
    echo "reads: \$reads" >> ${fq.baseName}.report.txt
    echo "gc_bases: \$gc" >> ${fq.baseName}.report.txt
    """

    stub:
    """
    touch ${fq.baseName}.report.txt
    """
}

workflow {
    GC_REPORT(channel.fromPath('data/*.fastq'))
}
