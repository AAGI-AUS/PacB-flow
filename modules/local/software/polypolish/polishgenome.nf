//-----------------------------------------
// polypolish: doi:10.1099/mgen.0.001254.
//-----------------------------------------

process POLYPOLISHFILT {

    label 'large_task'
    tag "Filter mapped reads."

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/polypolish:0.6.0--hdbdd923_0'  :
        'quay.io/biocontainers/polypolish:0.6.0--h4c94732_1'}"

    input:
        tuple val(sample_id), path(reads_mapped1), path(reads_mapped2)

    output:
        tuple val( sample_id ), path("${sample_id}_filt1.sam"), path("${sample_id}_filt2.sam"), emit: reads_filt
        path("versions.yml")                                                                  , emit: versions

    script:
    """
    polypolish filter \
	--in1 ${reads_mapped1} \
	--in2 ${reads_mapped2} \
	--out1 ${sample_id}_filt1.sam \
	--out2 ${sample_id}_filt2.sam

    cat <<-VERSIONS > versions.yml
    "${task.process}":
        polypolysh: \$(polypolish -V | cut -d" " -f2)
    VERSIONS
    """
}

process POLYPOLISHPOLISH {

    label 'large_task'
    tag "Polish genome with mapped reads."

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
       'https://depot.galaxyproject.org/singularity/polypolish:0.6.0--hdbdd923_0'  :
       'quay.io/biocontainers/polypolish:0.6.0--h4c94732_1'}"

    input:
        tuple val(sample_id), path(reads_filt1), path(reads_filt2), path(genome)

    output:
        tuple val( sample_id ), path("${sample_id}_polished.fasta"), emit: genome_polished
        path("versions.yml")                                        , emit: versions

    script:
    """
    polypolish polish \
	${genome} \
        ${reads_filt1} \
        ${reads_filt2} > ${sample_id}_polished.fasta

    cat <<-VERSIONS > versions.yml
    "${task.process}":
        polypolysh: \$(polypolish -V | cut -d" " -f2)
    VERSIONS
    """

}


