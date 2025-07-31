# Supported FASTA Extensions for Polypolish Mode

## Overview

The PacB-flow pipeline's Polypolish-only mode now supports multiple FASTA file extensions, providing flexibility for users with different file naming conventions.

## Supported Extensions

The following FASTA file extensions are supported in the `lr_reads` column for Polypolish-only mode:

- `.fasta` - Standard FASTA extension
- `.fna` - FASTA Nucleic Acid (common in NCBI)
- `.fa` - Short FASTA extension
- `.fas` - Alternative FASTA extension

## Example Usage

### Mixed Extensions in Single Manifest

```csv
sampleId,lr_reads,sr_read1,sr_read2
genome1,/data/assemblies/genome1.fasta,/data/reads/genome1_R1.fastq.gz,/data/reads/genome1_R2.fastq.gz
genome2,/data/assemblies/genome2.fna,/data/reads/genome2_R1.fastq.gz,/data/reads/genome2_R2.fastq.gz
genome3,/data/assemblies/genome3.fa,/data/reads/genome3_R1.fastq.gz,/data/reads/genome3_R2.fastq.gz
genome4,/data/assemblies/genome4.fas,/data/reads/genome4_R1.fastq.gz,/data/reads/genome4_R2.fastq.gz
```

### Running the Pipeline

```bash
nextflow run main.nf --polypolish_only --manifest mixed_extensions.csv
```

## Validation

The validation script will check for proper FASTA extensions:

```bash
python validate_manifest.py your_manifest.csv --polypolish
```

**Valid extensions will pass silently:**
```
✓ Row 1: genome1 - OK
✓ Row 2: genome2 - OK
```

**Invalid extensions will show warnings:**
```
WARNING: Row 1 (sample genome1): lr_reads file doesn't appear to be FASTA format (expected: .fasta, .fna, .fa, .fas)
```

## Benefits

1. **Flexibility**: Support for common FASTA naming conventions
2. **Compatibility**: Works with files from different sources (NCBI, custom assemblies, etc.)
3. **Validation**: Built-in checking to catch potential format issues
4. **Consistency**: Same validation and processing regardless of extension

## Technical Notes

- All supported extensions are treated identically by the pipeline
- File content validation is handled by the underlying tools (BWA, Polypolish)
- Extensions are case-insensitive in validation (e.g., `.FASTA` and `.fasta` both work)
- The pipeline does not modify or convert files based on extension

## Migration

If you have existing manifests with different FASTA extensions, no changes are needed - they should work automatically with the updated pipeline.