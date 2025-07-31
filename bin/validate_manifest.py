#!/usr/bin/env python3
"""
Validate PacB-flow manifest files
"""
import csv
import sys
import os
from pathlib import Path

def validate_standard_manifest(manifest_file):
    """Validate standard assembly manifest"""
    required_columns = ['sampleId', 'lr_reads', 'sr_read1', 'sr_read2']
    
    print(f"Validating standard manifest: {manifest_file}")
    
    if not os.path.exists(manifest_file):
        print(f"ERROR: Manifest file {manifest_file} does not exist!")
        return False
    
    try:
        with open(manifest_file, 'r') as f:
            reader = csv.DictReader(f)
            
            # Check headers
            if not all(col in reader.fieldnames for col in required_columns):
                print(f"ERROR: Missing required columns. Expected: {required_columns}")
                print(f"Found: {reader.fieldnames}")
                return False
            
            # Check each row
            for i, row in enumerate(reader, 1):
                sample_id = row.get('sampleId', '').strip()
                if not sample_id:
                    print(f"ERROR: Row {i}: Empty sampleId")
                    return False
                
                for col in required_columns[1:]:  # Skip sampleId, already checked
                    value = row.get(col, '').strip()
                    if not value:
                        print(f"ERROR: Row {i} (sample {sample_id}): Empty value for {col}")
                        return False
                    
                    # Check if file exists (optional warning)
                    if not os.path.exists(value):
                        print(f"WARNING: Row {i} (sample {sample_id}): File {value} does not exist")
                
                print(f"✓ Row {i}: {sample_id} - OK")
        
        print("✓ Manifest validation passed!")
        return True
        
    except Exception as e:
        print(f"ERROR: Failed to read manifest: {e}")
        return False

def validate_polypolish_manifest(manifest_file):
    """Validate polypolish-only manifest (same format as standard, but lr_reads contains FASTA)"""
    required_columns = ['sampleId', 'lr_reads', 'sr_read1', 'sr_read2']
    
    print(f"Validating polypolish manifest: {manifest_file}")
    print("Note: For polypolish-only mode, lr_reads column should contain FASTA files")
    
    if not os.path.exists(manifest_file):
        print(f"ERROR: Manifest file {manifest_file} does not exist!")
        return False
    
    try:
        with open(manifest_file, 'r') as f:
            reader = csv.DictReader(f)
            
            # Check headers
            if not all(col in reader.fieldnames for col in required_columns):
                print(f"ERROR: Missing required columns. Expected: {required_columns}")
                print(f"Found: {reader.fieldnames}")
                return False
            
            # Check each row
            for i, row in enumerate(reader, 1):
                sample_id = row.get('sampleId', '').strip()
                if not sample_id:
                    print(f"ERROR: Row {i}: Empty sampleId")
                    return False
                
                for col in required_columns[1:]:  # Skip sampleId, already checked
                    value = row.get(col, '').strip()
                    if not value:
                        print(f"ERROR: Row {i} (sample {sample_id}): Empty value for {col}")
                        return False
                    
                    # Check if file exists (optional warning)
                    if not os.path.exists(value):
                        print(f"WARNING: Row {i} (sample {sample_id}): File {value} does not exist")
                    
                    # Special check for polypolish mode - lr_reads should be FASTA
                    if col == 'lr_reads':
                        if not any(value.lower().endswith(ext) for ext in ['.fasta', '.fa', '.fas']):
                            print(f"WARNING: Row {i} (sample {sample_id}): lr_reads file doesn't appear to be FASTA format")
                
                print(f"✓ Row {i}: {sample_id} - OK")
        
        print("✓ Manifest validation passed!")
        return True
        
    except Exception as e:
        print(f"ERROR: Failed to read manifest: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python validate_manifest.py <manifest_file> [--polypolish]")
        print("       python validate_manifest.py <manifest_file>  # for standard assembly")
        print("       python validate_manifest.py <manifest_file> --polypolish  # for polypolish-only")
        sys.exit(1)
    
    manifest_file = sys.argv[1]
    is_polypolish = len(sys.argv) > 2 and sys.argv[2] == '--polypolish'
    
    if is_polypolish:
        success = validate_polypolish_manifest(manifest_file)
    else:
        success = validate_standard_manifest(manifest_file)
    
    sys.exit(0 if success else 1)