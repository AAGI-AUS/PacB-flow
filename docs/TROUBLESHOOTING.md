# PacB-flow Troubleshooting Guide

## Common Errors and Solutions

### Error: "Argument of `file` function cannot be null"

This error occurs when the manifest CSV file has empty cells or missing values.

**Causes:**
1. Empty cells in the CSV file
2. Missing columns in the header
3. Trailing commas in CSV rows
4. Inconsistent number of columns

**Solutions:**

1. **Validate your manifest file:**
   ```bash
   python validate_manifest.py your_manifest.csv
   # or for polypolish-only mode:
   python validate_manifest.py your_manifest.csv --polypolish
   ```

2. **Check CSV format:**
   - Ensure no empty cells
   - All required columns are present
   - No trailing commas
   - Consistent number of columns in each row

3. **Unified manifest format (same for both modes):**
   ```csv
   sampleId,lr_reads,sr_read1,sr_read2
   sample1,/path/to/longreads.fastq.gz,/path/to/R1.fastq.gz,/path/to/R2.fastq.gz
   ```

4. **For polypolish-only mode, use the same format but put FASTA in lr_reads column:**
   ```csv
   sampleId,lr_reads,sr_read1,sr_read2
   sample1,/path/to/assembly.fasta,/path/to/R1.fastq.gz,/path/to/R2.fastq.gz
   ```

### Error: File not found

**Solutions:**
1. Use absolute paths in your manifest
2. Ensure all files exist before running the pipeline
3. Check file permissions

### Error: Missing required parameters

**Solutions:**
1. For standard mode: `nextflow run main.nf --manifest your_manifest.csv`
2. For polypolish-only: `nextflow run main.nf --polypolish_only --manifest your_manifest.csv`

## Validation Steps

1. **Check manifest format:**
   ```bash
   head -5 your_manifest.csv
   ```

2. **Validate manifest:**
   ```bash
   python validate_manifest.py your_manifest.csv
   ```

3. **Test pipeline syntax:**
   ```bash
   nextflow run main.nf --help
   ```

4. **Dry run (preview mode):**
   ```bash
   nextflow run main.nf --manifest your_manifest.csv -preview
   ```

## Getting Help

If you continue to have issues:
1. Check the `.nextflow.log` file for detailed error messages
2. Ensure all input files exist and are readable
3. Verify the CSV format matches the expected structure
4. Use the validation script to check your manifest file