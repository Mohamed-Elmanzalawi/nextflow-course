// Where does params.title come from? Try it with and without
// nextflow.config, -params-file and --title (Lesson 3.3, section C).
params {
    title: String = 'from the script'
}

workflow {
    println "title = ${params.title}"
}
