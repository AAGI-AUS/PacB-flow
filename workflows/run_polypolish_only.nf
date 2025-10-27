/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { POLISH_GENOME }                           from '../subworkflows/local/run_polypolish/main'
include { ABYSS_FAC }                               from '../modules/local/software/abyss/abyssfac-stats'
include { CLEANUP_GENOME }                          from '../subworkflows/local/cleanup_genomes_final/main'
include { MITOCONDRION_DOWNLOAD }                   from '../modules/local/software/download/downloadmito'

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
        // Same format as standard: sampleId,lr_reads,sr_read1,sr_read2
        // For polypolish-only: lr_reads column contains the FASTA file
        // Convert to format expected by POLISH_GENOME: sample_pair_genome and genome
        //
        // Create sample_pair_genome channel: tuple [ sample, reads_pair1, reads_pair2 ]
	ch_samplesheet
    		.map { meta, fasta, fastq_1, fastq_2 ->
        		def sample_id = meta.id
        		tuple(sample_id, fastq_1, fastq_2)
    		}
    		.set { sample_pair_reads }

	// Create genome channel: tuple [ sample, genome ]
	ch_samplesheet
    		.map { meta, fasta, fastq_1, fastq_2 ->
        		def sample_id = meta.id
        		tuple(sample_id, fasta)
    		}
    		.set { genome }
        // sample_pair_reads.view()

        //
        // SUBWORKFLOW: Polish genome with Polypolish
        //
        POLISH_GENOME(
            sample_pair_reads,
            genome
        )

        //
        // MODULE: Generate assembly statistics
        //
        POLISH_GENOME.out.assembly
            .map { sample, fasta -> fasta }
            .collect()
            .set { ch_all_assemblies }
        
        // Download the database
	MITO_CHECK = MITOCONDRION_DOWNLOAD(params.mito_dw)

	// Cleanup final genome
	CLEANED_GENOME = CLEANUP_GENOME(POLISH_GENOME.out.assembly, MITO_CHECK.mito_ref)

        ABYSS_FAC(ch_all_assemblies)
        ch_versions = ch_versions.mix(ABYSS_FAC.out.versions)

    emit:
        polished_assemblies  = POLISH_GENOME.out.assembly
        cleanup_final_genome = CLEANED_GENOME.out_genome
        stats                = ABYSS_FAC.out.assembly_stats
        versions             = ch_versions
}
