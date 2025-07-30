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
      nextflow run main.nf --polypolish_only --manifest samplesheet_polypolish.csv
      
    For Polypolish-only mode, the samplesheet should contain:
      sampleId,fasta,fastq_1,fastq_2
      
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
		// Expected format: sample,fasta,fastq_1,fastq_2
		if (params.manifest) { 
			Channel.fromPath( params.manifest )
				.splitCsv( header: true, sep: ',' )
				.map { row -> 
					def meta = [id: row.sampleId]
					tuple( meta, file(row.fasta), file(row.fastq_1), file(row.fastq_2) ) 
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
