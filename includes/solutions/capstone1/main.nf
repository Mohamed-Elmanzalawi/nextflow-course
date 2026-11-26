params {
    // Samplesheet with columns: sample,fastq_1,fastq_2
    input: Path = 'samplesheet.csv'
}

process FASTQC {
    tag "${meta.id}"
    cpus 2
    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'
    conda 'bioconda::fastqc=0.12.1'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.html'), emit: html
    tuple val(meta), path('*.zip'), emit: zip

    script:
    """
    fastqc --threads ${task.cpus} --quiet ${reads}
    """
}

process MULTIQC {
    container 'quay.io/biocontainers/multiqc:1.35--pyhdfd78af_2'
    conda 'bioconda::multiqc=1.35'

    input:
    path qc_files

    output:
    path 'multiqc_report.html', emit: report
    path 'multiqc_report_data', emit: data

    script:
    """
    multiqc --filename multiqc_report.html .
    """
}

workflow {
    main:
    samples = channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample, single_end: false]
            tuple(meta, [file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true)])
        }

    FASTQC(samples)
    zips = FASTQC.out.zip.map { _meta, zip -> zip }.flatten().collect()
    MULTIQC(zips)

    publish:
    fastqc = FASTQC.out.html
    multiqc = MULTIQC.out.report
    multiqc_data = MULTIQC.out.data
}

output {
    fastqc {
        path 'fastqc'
    }
    multiqc {
        path '.'
    }
    multiqc_data {
        path '.'
    }
}
