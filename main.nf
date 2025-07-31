#!/usr/bin/env nextflow

//Call DSL2
nextflow.enable.dsl=2

// Print help message
def helpMessage() {
    log.info"""
    Usage:
    
    Standard PacB-flow assembly pipeline:
      nextflow run main.nf --manifest samples.csv
    
    Polypolish-only mode (polish existing assemblies):
      nextflow run main.nf --polypolish_only --manifest samples.csv
      
    Both modes use the same manifest format:
      sampleId,lr_reads,sr_read1,sr_read2
      
    For standard mode: lr_reads = long reads (PacBio)
    For polypolish-only mode: lr_reads = assembly FASTA file (.fasta/.fna/.fa/.fas)
      
    See docs/polypolish_only_mode.md for more details.
    """.stripIndent()
}

// Show help message
if (params.help) {
    helpMessage()
    exit 0
}

/*  ======================================================================================================
 *  HELP MENU
 *  ======================================================================================================
 */
//ver = manifest.version


//Input parameters list
params.help      = null
params.outputdir = "results"

//--------------------------------------------------------------------------------------------------------
// Validation - validation from nf-core for input results

include { validateParameters; paramsHelp; paramsSummaryLog; fromSamplesheet } from 'plugin/nf-validation'

if (params.help) {
   log.info paramsHelp("nextflow run ...")
   exit 0
}

// Validate input parameters
validateParameters()

// Print summary of supplied parameters
log.info paramsSummaryLog(workflow)

//--------------------------------------------------------------------------------------------------------
// Main workflow 
include { PBFLOW_WORKFLOW } from './workflows/run_pacbassembly.nf'
include { POLYPOLISH_ONLY } from './workflows/run_polypolish_only.nf'

workflow {

	if (params.polypolish_only) {
		// Parse manifest for polypolish-only mode
		// Same format as standard: sampleId,lr_reads,sr_read1,sr_read2
		// For polypolish-only: lr_reads column contains the FASTA file
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
					def meta = [id: row.sampleId]
					// For polypolish-only mode, lr_reads column contains the FASTA file
					tuple( meta, file(row.lr_reads), file(row.sr_read1), file(row.sr_read2) ) 
				}
				.set { ch_samplesheet }
		} else { 
			exit 1, 'No manifest file provided. Please specify samples file for polypolish-only mode.'
		}
		
		POLYPOLISH_ONLY(ch_samplesheet)
		
	} else {
		PBFLOW_WORKFLOW()
	}

}
