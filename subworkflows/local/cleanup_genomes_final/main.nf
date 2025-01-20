//
// Subworkflow - cleanup genome
//

include { SEQKIT_LISTRENAME }                    from '../../../modules/local/software/seqkit/renamefasta'
include { SEQKIT_RENAMEGEN }                     from '../../../modules/local/software/seqkit/renamefasta'
include { MITO_ALIGN }                           from '../../../modules/local/software/minimap/check_mito'
include { SEQKIT_MITOTAG }                       from '../../../modules/local/software/seqkit/renamefasta'

workflow CLEANUP_GENOME {

    take:
        genome        // tuple [ sample, genome ]
	mito_ref      // path to download

    main:
	
	// cleanup naming in pipeline
	genome.map { tuple ->
        // Extract sample and path from the tuple
        def (sample, genome) = tuple
        // Remove ".ntlink" and ".ntjoin" from the sample string
        def cleanedSample = sample.replaceAll(/\.ntlink|\.ntjoin/, '')
        // Return the modified tuple with the cleaned sample name and original path
        return [ cleanedSample, genome ] }
	.set { genome_orig }

	LIST_NAMS = SEQKIT_LISTRENAME(genome_orig)
	
	// join channels for same sample id
	LIST_NAMS.list_scafs.join(genome_orig)
		.set { ch_genome_orig_nams }

	ASSEMBLY_RENAM = SEQKIT_RENAMEGEN(
		ch_genome_orig_nams
		)
	
	LIST_MITO = MITO_ALIGN(ASSEMBLY_RENAM.renamed_fasta, mito_ref)
	LIST_MITO.list_mito.join(ASSEMBLY_RENAM.renamed_fasta)
		.set { ch_renamed_fasta_mito }

	FINAL_GENOME = SEQKIT_MITOTAG(ch_renamed_fasta_mito)		

    emit:
	out_genome = FINAL_GENOME.mito_fasta

}

