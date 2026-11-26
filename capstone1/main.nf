// Capstone 1: FastQC on every sample of a samplesheet, then one MultiQC report.
// The requirements are on the course page "Capstone 1".
// Run:    nextflow run main.nf -profile docker      (or -profile conda)
// Check:  bash check_capstone.sh

// TODO: a params block with 'input', the samplesheet (a Path), default 'samplesheet.csv'

// TODO: process FASTQC: one task per sample, tagged with the sample name

// TODO: process MULTIQC: one task for all samples

workflow {
    // TODO: samplesheet → channel of [meta, [R1, R2]]  (Lessons 5.2 and 5.4)
    // TODO: run FASTQC on every sample, then MULTIQC on all FastQC zip files at once
    // TODO: publish the FastQC HTML reports and the MultiQC report
}
