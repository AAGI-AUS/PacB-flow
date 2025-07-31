//--------------------------------------------------
// Workflow assembly PB
//--------------------------------------------------

include { ASSEMBLY_PIPELINE } from '../subworkflows/local/run_pacbassembly/main'

// Parse manifest here
if (params.manifest) { 
	Channel.fromPath( params.manifest )
		.splitCsv( header: true, sep: ',' )
		.map { row -> 
			// Validate that all required fields are present and not empty
			if (!row.sampleId || !row.lr_reads || !row.sr_read1 || !row.sr_read2) {
				error "Missing required fields in manifest for sample: ${row.sampleId ?: 'unknown'}. Required: sampleId, lr_reads, sr_read1, sr_read2"
			}
			if (row.sampleId.toString().trim().isEmpty() || 
			    row.lr_reads.toString().trim().isEmpty() || 
			    row.sr_read1.toString().trim().isEmpty() || 
			    row.sr_read2.toString().trim().isEmpty()) {
				error "Empty values found in manifest for sample: ${row.sampleId}. All fields must have values."
			}
			tuple( row.sampleId, file(row.lr_reads), file(row.sr_read1), file(row.sr_read2) ) 
		}
		.set { sample_run_ch } 
} else { 
	exit 1, 'No manifest file provided. Please specify samples file.'
}

//if (params.ntjoin_ref) { Channel.fromPath( params.ntjoin_ref, checkIfExists: true) } else { exit 1, 'No reference genome specified'}

workflow PBFLOW_WORKFLOW {

	sample_run_ch.map { sample, lr_reads, sr1_reads, sr2_reads ->
                             tuple(sample, lr_reads)}
			.set { sample_lr_ch }
	
	sample_run_ch.map { sample, lr_reads, sr1_reads, sr2_reads ->
                             tuple(sample, sr1_reads, sr2_reads)}
                        .set { sample_sr_ch }

	ASSEMBLY_PIPELINE(
		sample_lr_ch,
		sample_sr_ch
	)

}
	
