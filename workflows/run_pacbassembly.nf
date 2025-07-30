//--------------------------------------------------
// Workflow assembly PB
//--------------------------------------------------

include { ASSEMBLY_PIPELINE } from '../subworkflows/local/run_pacbassembly/main'

// Parse manifest here
if (params.manifest) { Channel.fromPath( params.manifest )
	.splitCsv( header: true, sep: ',' )
	.map { row -> tuple( row.sampleId, file(row.lr_reads), file(row.sr_read1), file(row.sr_read2) ) }
	.set { sample_run_ch } } else { exit 1, 'No manifest file provided. Please specify samples file.'}

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
	
