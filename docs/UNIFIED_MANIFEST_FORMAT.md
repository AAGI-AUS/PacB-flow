# Unified Manifest Format for PacB-flow

## Overview

Both standard assembly and Polypolish-only modes now use the **same manifest format**, making it easier for users to switch between modes without changing their input files.

## Manifest Format

```csv
sampleId,lr_reads,sr_read1,sr_read2
```

### Column Descriptions:

- **`sampleId`**: Unique sample identifier
- **`lr_reads`**: 
  - **Standard mode**: Long reads file (PacBio FASTQ)
  - **Polypolish-only mode**: Assembly FASTA file (.fasta, .fna, .fa, .fas)
- **`sr_read1`**: Short reads R1 (Illumina FASTQ)
- **`sr_read2`**: Short reads R2 (Illumina FASTQ)

## Usage Examples

### Standard Assembly Mode
```bash
nextflow run main.nf --manifest samples.csv
```

**Example manifest:**
```csv
sampleId,lr_reads,sr_read1,sr_read2
sample1,/path/to/sample1_longreads.fastq.gz,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
sample2,/path/to/sample2_longreads.fastq.gz,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz
```

### Polypolish-Only Mode
```bash
nextflow run main.nf --polypolish_only --manifest samples.csv
```

**Example manifest (same format, different content in lr_reads column):**
```csv
sampleId,lr_reads,sr_read1,sr_read2
sample1,/path/to/sample1_assembly.fasta,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
sample2,/path/to/sample2_assembly.fna,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz
sample3,/path/to/sample3_assembly.fa,/path/to/sample3_R1.fastq.gz,/path/to/sample3_R2.fastq.gz
```

**Supported FASTA extensions**: .fasta, .fna, .fa, .fas

## Benefits

1. **Consistency**: Same format for both modes
2. **Simplicity**: Users don't need to remember different column names
3. **Flexibility**: Easy to switch between modes
4. **Compatibility**: Existing manifests work with minor modifications

## Validation

Use the validation script to check your manifest:

```bash
# For standard mode
python validate_manifest.py samples.csv

# For polypolish-only mode
python validate_manifest.py samples.csv --polypolish
```

## Migration from Old Format

If you have old polypolish manifests with `fasta,fastq_1,fastq_2` columns, simply rename:
- `fasta` → `lr_reads`
- `fastq_1` → `sr_read1`  
- `fastq_2` → `sr_read2`