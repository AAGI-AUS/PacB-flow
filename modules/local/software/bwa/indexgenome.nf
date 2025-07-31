//-----------------------------------------
// bwa: https://doi.org/10.1093/bioinformatics/btp324
//-----------------------------------------

process BWA_INDEX {

    label 'medium_task'
    tag "Index reference genome."

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bwa:0.7.18--he4a0461_1'  :
        'quay.io/biocontainers/bwa:0.7.18--he4a0461_1'}"

    input:
        tuple val(sample_id), path(genome)

    output:
	tuple val(sample_id), path( genome ), path("${sample_id}.index*"), emit: index
	path("versions.yml")                             , emit: versions

    script:
    """
    bwa index ${genome} -p ${sample_id}.index

    cat <<-VERSIONS > versions.yml
    "${task.process}":
	bwa: \$(bwa 2>&1 | grep \"Version\" | awk '{print \$2}')
    VERSIONS
    """
}
