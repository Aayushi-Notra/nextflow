params.transcriptome_file = "$projectDir/data/ggal/transcriptome.fa"
params.reads = "$projectDir/data/samplesheet.csv"

process INDEX {
    container "quay.io/biocontainers/salmon:1.10.1--h7e5ed60_0"
    publishDir "results", mode: 'copy'

    input:
    path transcriptome

    output:
    path 'salmon_index'

    script:
    """
    salmon index --transcripts $transcriptome --index salmon_index
    """
}

process FASTQC {
  tag "fastqc on ${sample_id}"  
  container "quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0"
  publishDir "results", mode: 'copy'

  input:
    tuple val(sample_id), path(reads_1), path(reads_2)

  output:
    path "fastqc_${sample_id}_logs"

  script:
  """
  mkdir -p "fastqc_${sample_id}_logs"
  fastqc --outdir "fastqc_${sample_id}_logs" --format fastq $reads_1 $reads_2 -t $task.cpus
  """
}

process QUANTIFICATION {
  tag "salmon on ${sample_id}"  
  container "quay.io/biocontainers/salmon:1.10.1--h7e5ed60_0"
  publishDir "results", mode: 'copy'

  input:
    path salmon_index
    tuple val(sample_id), path(reads_1), path(reads_2)

  output:
    path "$sample_id"

  script:
  """
    salmon quant --libType=U -i $salmon_index -1 $reads_1 -2 $reads_2 -o $sample_id
  """
}

process MULTIQC {
  container "quay.io/biocontainers/multiqc:1.19--pyhdfd78af_0"
  publishDir "results", mode: 'copy'

  input:
  path "*"

  output:
    path 'multiqc_report.html'
    path 'multiqc_data'

  script:
  """
  multiqc .
  """
}

workflow {

    // Run the index step with the transcriptome parameter
    INDEX(params.transcriptome_file)
    // Define the fastqc input channel
    reads_in = Channel.fromPath(params.reads)
        .splitCsv(header: true)
        .map { row -> [row.sample, file(row.fastq_1), file(row.fastq_2)] }
    //Run thefastqcstep with reads_in channel 
    FASTQC(reads_in)  
    //you could either run it as : QUANTIFICATION(INDEX.out[0])  
    //Define the quantification channel for the index files 
    transcriptome_index_in = INDEX.out[0]
    QUANTIFICATION(transcriptome_index_in, reads_in)

    //Define multiqc input channel 
    MULTIQC_IN =FASTQC.out[0]
        .mix(QUANTIFICATION.out[0])
        .collect() 
    MULTIQC(MULTIQC_IN)      

}


