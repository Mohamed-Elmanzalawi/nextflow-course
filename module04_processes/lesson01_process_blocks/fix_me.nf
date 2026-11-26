// Lesson 4.1 challenge: this script doesn't even start. Fix it, then add a stub.
// Run it with:  nextflow run fix_me.nf      Check it with:  bash check_fix_me.sh

process GC_REPORT {
    input:
    path fq

    output:
    path "${fq.baseName}.report.txt"

    script:
    """
    sleep 3    # pretend this is a slow tool
    reads=$(awk 'END { print NR / 4 }' ${fq})
    gc=$(awk 'NR % 4 == 2' ${fq} | tr -cd 'GC' | wc -c | tr -d ' ')
    echo "sample: ${fq.baseName}" > ${fq.baseName}.report.txt
    echo "reads: $reads" >> ${fq.baseName}.report.txt
    echo "gc_bases: $gc" >> ${fq.baseName}.report.txt
    """
}

workflow {
    GC_REPORT(channel.fromPath('data/*.fastq'))
}
