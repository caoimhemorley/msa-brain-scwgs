#!/bin/bash -l

set -euo pipefail

PICARD_JAR="/path/to/picard.jar"

INPUT_DIR="/path/to/input_bams"
OUTPUT_DIR="/path/to/output_bams"

mkdir -p "$OUTPUT_DIR"

find "$INPUT_DIR" \
    -type f \
    -name "*.sorted.bam" \
    -print0 |
while IFS= read -r -d '' BAM; do

    BASENAME=$(basename "$BAM" ".sorted.bam")

    SAMPLE_NAME="$BASENAME"

    RG_BAM="${OUTPUT_DIR}/${BASENAME}.rg.sorted.bam"
    MARKDUP_BAM="${OUTPUT_DIR}/${BASENAME}.rg.markdup.bam"
    METRICS="${OUTPUT_DIR}/${BASENAME}.markdup_metrics.txt"

    echo "Processing: $BASENAME"

    java -jar "$PICARD_JAR" AddOrReplaceReadGroups \
        I="$BAM" \
        O="$RG_BAM" \
        RGID="$SAMPLE_NAME" \
        RGLB="lib1" \
        RGPL="ILLUMINA" \
        RGPU="unit1" \
        RGSM="$SAMPLE_NAME" \
        VALIDATION_STRINGENCY=LENIENT

    samtools index "$RG_BAM"

    java -jar "$PICARD_JAR" MarkDuplicates \
        I="$RG_BAM" \
        O="$MARKDUP_BAM" \
        M="$METRICS" \
        CREATE_INDEX=true \
        VALIDATION_STRINGENCY=LENIENT

    echo "Completed: $BASENAME"

done

echo "Read group assignment and duplicate marking complete."
