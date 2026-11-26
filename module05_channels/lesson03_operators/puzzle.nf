// Lesson 5.3 challenge: an operator puzzle.
// Each part prints its channel. Add operators BEFORE each .view() so the output matches the GOAL.
// Run:  nextflow -q run puzzle.nf      Check:  bash check_puzzle.sh

workflow {
    // A. GOAL: the squares of the EVEN numbers only:  A: 4  A: 16  A: 36  A: 64  A: 100
    numbers = channel.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    numbers.view { v -> "A: ${v}" }

    // B. GOAL: one line per sample with its read count AND its GC%:  B: [cov_a, 100, 37.9] ...
    counts = channel.of(['cov_a', 100], ['cov_b', 100], ['hsa_rna', 4159])
    gc = channel.of(['hsa_rna', 48.1], ['cov_a', 37.9], ['cov_b', 38.4])
    counts.view { v -> "B: ${v}" }

    // C. GOAL: every patient once, with the list of its lanes:  C: [pt01, [L001, L002, L003]] ...
    lanes = channel.of(['pt01', 'L001'], ['pt02', 'L001'], ['pt01', 'L002'], ['pt02', 'L002'], ['pt01', 'L003'])
    lanes.view { v -> "C: ${v}" }

    // D. GOAL: every (sample, reference) pair that makes sense: cov_* samples with MN908947
    //    (SARS-CoV-2), hsa_* samples with GRCh38 (human):  D: [cov_a, MN908947] ...
    samples = channel.of('cov_a', 'cov_b', 'hsa_rna')
    references = channel.of('MN908947', 'GRCh38')
    samples.view { v -> "D: ${v}" }

    // E. GOAL: ONE line with the total number of reads of all samples:  E: 4359
    counts.view { v -> "E: ${v}" }

    // F. GOAL: ONE line with the total number of FASTQ files:  F: 5
    file_lists = channel.of(['a_R1.fq', 'a_R2.fq'], ['b_R1.fq', 'b_R2.fq'], ['c.fq'])
    file_lists.view { v -> "F: ${v}" }
}
