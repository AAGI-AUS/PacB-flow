/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { POLISH_GENOME }                           from '../subworkflows/local/run_polypolish/main'
include { ABYSS_FAC }                               from '../modules/local/software/abyss/abyssfac-stats'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow POLYPOLISH_ONLY {

    take:
        ch_samplesheet // channel: samplesheet read in from --input

    main:

        ch_versions = Channel.empty()

        //
        // Parse samplesheet for polypolish-only mode
        // Expected format: sample,fasta,fastq_1,fastq_2
        // Convert to format expected by POLISH_GENOME: sample_pair_genome and genome
        //
        ch_samplesheet
            .map { meta, fasta, fastq_1, fastq_2 ->
                // Create the two channels needed by POLISH_GENOME
                def sample_id = meta.id
                return [
                    tuple(sample_id, fastq_1, fastq_2),  // sample_pair_genome format
                    tuple(sample_id, fasta)              // genome format
                ]
            }
            .transpose()
            .branch {
                reads: it.size() == 3  // sample, fastq_1, fastq_2
                    return it
                genome: it.size() == 2  // sample, fasta
                    return it
            }
            .set { ch_input }

        //
        // SUBWORKFLOW: Polish genome with Polypolish
        //
        POLISH_GENOME(
            ch_input.reads,
            ch_input.genome
        )

        //
        // MODULE: Generate assembly statistics
        //
        POLISH_GENOME.out.assembly
            .map { sample, fasta -> fasta }
            .collect()
            .set { ch_all_assemblies }

        ABYSS_FAC(ch_all_assemblies)
        ch_versions = ch_versions.mix(ABYSS_FAC.out.versions)

    emit:
        polished_assemblies = POLISH_GENOME.out.assembly
        stats              = ABYSS_FAC.out.stats
        versions           = ch_versions
}