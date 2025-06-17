//
// Subworkflow - assembly
//

include { CANU_ASSEMBLY }                           from '../../../modules/local/software/canu/assemblereads'
include { FLYE }                                    from '../../../modules/nf-core/flye/main'
include { ABYSS_FAC }                               from '../../../modules/local/software/abyss/abyssfac-stats'
include { NTJOIN_SCAFFOLD }                         from '../../../modules/local/software/ntjoin/scaffoldassembly'
include { NTLINK_SCAFFOLD }                         from '../../../modules/local/software/ntlink/scaffoldassembly'
include { COVERAGE_CALCULATE as COV_PRIMARY }       from '../../../subworkflows/local/calculate_coverage/main'
include { COVERAGE_CALCULATE as COV_SCAF }          from '../../../subworkflows/local/calculate_coverage/main'
include { COVERAGE_CALCULATE as COV_SCAFREF }       from '../../../subworkflows/local/calculate_coverage/main'
include { POLISH_GENOME }                           from '../../../subworkflows/local/run_polypolish/main'
include { CLEANUP_GENOME }                          from '../../../subworkflows/local/cleanup_genomes_final/main'
include { MITOCONDRION_DOWNLOAD }                   from '../../../modules/local/software/download/downloadmito'

// Define functions
def collectAssemblies(ASSEMBLY, allAssembliesChannel) {
        return ASSEMBLY.map { it -> it[1] }
        .mix(allAssembliesChannel)
        .collect()
        }

workflow ASSEMBLY_PIPELINE {

    take:
        assembly_lr // tuple [sample, lr_reads ]
        assembly_sr // tuple [sample, sr1_reads, sr2_reads] // reads may be null

    main:
        //
        allAssembliesChannel = Channel.empty()

        // Initialize ASSEMBLY variable
        ASSEMBLY = [:]
        ch_versions = Channel.empty()

        // Choose assembly method based on parameter
        if (params.assembler == 'flye') {

            // Prepare input for FLYE module with scaffold info in meta
            flye_input_ch = assembly_lr.map { sample, reads ->
                def meta = [
                id: sample,
                scaffold: params.flye_scaffold ?: false,
                iterations: params.flye_iterations ?: 1
                ]
                tuple(meta, reads)
            }

            // Call FLYE process with correct parameters
            FLYE_ASSEMBLY = FLYE(
                flye_input_ch,
                '--pacbio-hifi'  // String parameter
            )

            FLYE_ASSEMBLY_OUT = [
                assembly: FLYE_ASSEMBLY.fasta.map { meta, fasta_primary ->
                    tuple(meta.id, fasta_primary)
                },
                versions: FLYE_ASSEMBLY.versions
            ]

            // Fix join operation - ensure keys match
            assembly_lr.join(FLYE_ASSEMBLY_OUT.assembly)
                       .set { ch_readslr_assembly }
            COV_PRIMARY(ch_readslr_assembly)

            ASSEMBLY = FLYE_ASSEMBLY_OUT

            // Cleanup final genome
            // Download the database
            // MITO_CHECK = MITOCONDRION_DOWNLOAD(params.mito_dw)
            // CLEANED_GENOME = CLEANUP_GENOME(ASSEMBLY.assembly, MITO_CHECK.mito_ref)

            ch_versions = ch_versions.mix(FLYE_ASSEMBLY_OUT.versions)

        } else {
            // Default to CANU assembly
            CANU_ASSEMBLY_OUT = CANU_ASSEMBLY(assembly_lr)

            // Fix join operation - ensure keys match
            assembly_lr.join(CANU_ASSEMBLY_OUT.assembly)
                       .set { ch_readslr_assembly }
            COV_PRIMARY(ch_readslr_assembly)

            ASSEMBLY = CANU_ASSEMBLY_OUT
            ch_versions = ch_versions.mix(CANU_ASSEMBLY_OUT.versions)
        }

        // collect assemblies
        collectAssemblies(ASSEMBLY.assembly, allAssembliesChannel)
            .set { all_assemblies }

        // Default suffix
        nam_suffix = ''

        // Long read scaffolding (ntLink) if ntlink_run is True
        if (params.ntlink_run) {

            // ensure samples matching
            assembly_lr.join(ASSEMBLY.assembly)
                    .set { ch_assembly_lr_primary_assembly }

            // scaffold with long reads
            NTLINK_OUT = NTLINK_SCAFFOLD(ch_assembly_lr_primary_assembly)
            ASSEMBLY = NTLINK_OUT

            nam_suffix = ".ntlink"
            // Update `assembly_lr_scaf` with suffix after ntLink
            assembly_lr.map { val, path -> tuple("${val}${nam_suffix}", path) }
                       .set { assembly_lr_scaf }
            // Join ntLink assembly and run COV_SCAF
            assembly_lr_scaf.join(ASSEMBLY.assembly)
                            .set { ch_readslr_assembly_scaf }
            // Run COV_SCAF at ntLink stage
            COV_SCAF(ch_readslr_assembly_scaf)

            MITO_CHECK = MITOCONDRION_DOWNLOAD(params.mito_dw)
            CLEANED_GENOME = CLEANUP_GENOME(ASSEMBLY.assembly, MITO_CHECK.mito_ref)

            // Ensure the assembly after ntLink is mixed into all assemblies
            collectAssemblies(ASSEMBLY.assembly, all_assemblies)
                .set { all_assemblies }

        }

        // NTJoin scaffolding (if ntjoin_ref is provided)
        if (params.ntjoin_ref) {
            if (file(params.ntjoin_ref).exists()) {
                ntJoin_input_ref = file(params.ntjoin_ref)
            } else {
                throw new FileNotFoundException("File ${params.ntjoin_ref} does not exist.")
            }

            if (params.ntlink_run) {
                // Wait for ntLink to finish before running NTJoin
                ch_readslr_assembly_scaf
                    .set { delayed_assembly_lr_scaf }
                // Now run NTJOIN_SCAFFOLD on the delayed channel
                NTJOIN_OUT = NTJOIN_SCAFFOLD(ASSEMBLY.assembly, ntJoin_input_ref)
                ASSEMBLY = NTJOIN_OUT

                // Update `assembly_lr_scafref` with suffix after NTJoin
                delayed_assembly_lr_scaf.map { val, reads, fasta -> tuple("${val}.ntjoin", reads) }
                                    .set { assembly_lr_scafref }

                // Join NTJoin assembly and run COV_SCAFREF
                assembly_lr_scafref.join(ASSEMBLY.assembly)
                               .set { ch_readslr_assembly_scaf_ref }

                // Run COV_SCAFREF at NTJoin stage
                COV_SCAFREF(ch_readslr_assembly_scaf_ref)

                // Ensure the assembly after ntJoin is mixed into all assemblies
                collectAssemblies(ASSEMBLY.assembly, all_assemblies)
                        .set { all_assemblies }

            } else {
                // If only ntJoin_ref is provided, run NTJOIN directly
                NTJOIN_OUT = NTJOIN_SCAFFOLD(ASSEMBLY.assembly, ntJoin_input_ref)
                ASSEMBLY = NTJOIN_OUT

                // Update `assembly_lr_scafref` with suffix after NTJoin
                assembly_lr.map { val, path -> tuple("${val}.ntjoin", path) }
                       .set { assembly_lr_scafref }

                // Join NTJoin assembly and run COV_SCAFREF
                assembly_lr_scafref.join(ASSEMBLY.assembly)
                        .set { ch_readslr_assembly_scaf_refOnly }

                // Run COV_SCAFREF at NTJoin stage
                COV_SCAFREF(ch_readslr_assembly_scaf_refOnly)

                // Ensure the assembly after ntJoin is mixed into all assemblies
                collectAssemblies(ASSEMBLY.assembly, all_assemblies)
                        .set { all_assemblies }
            }
        }

        // Handle short read naming for polishing
        assembly_sr.map { val, reads1, reads2 ->
            if (params.ntlink_run && params.ntjoin_ref) {
                tuple("${val}.ntlink.ntjoin", reads1, reads2)
            } else if (params.ntlink_run) {
                tuple("${val}.ntlink", reads1, reads2)
            } else if (params.ntjoin_ref) {
                tuple("${val}.ntjoin", reads1, reads2)
            } else {
                tuple(val, reads1, reads2)
            }
        }.set { assembly_sr_scafref }

        if (params.polish_genome) {
            assembly_sr_scafref
            .filter { sample, reads1, reads2 ->
                reads1 != null && reads2 != null
            }
            .ifEmpty {
                log.info "No samples with short reads found - skipping polishing for all samples"
                //Channel.empty()
                ASSEMBLY.assembly.view {"TEST"}
            }
            .set { samples_with_sr }

            // Only run polishing if channel is not empty
            if (samples_with_sr) {
                POLISH_OUT = POLISH_GENOME(samples_with_sr, ASSEMBLY.assembly)
                ASSEMBLY = POLISH_OUT
            }

        } else {
            log.info "Genome polishing disabled (polish_genome=false)"
        }

        collectAssemblies(ASSEMBLY.assembly, all_assemblies)
               .set { all_assemblies }

        // Run stats on final output
        ABYSS_FAC(all_assemblies)

        emit:
        versions = ch_versions
        scaffolded = ASSEMBLY.assembly
        cleanup_final_genome = CLEANED_GENOME.out_genome
}
