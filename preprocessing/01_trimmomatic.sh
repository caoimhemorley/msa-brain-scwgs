#!/bin/bash -l

#$ -l h_rt=24:00:00
#$ -l mem=8G
#$ -pe smp 4
#$ -N trimmomatic_headcrop

set -euo pipefail

conda activate bowtie2

THREADS=4

BASE_DIR="/path/to/project"
INPUT_DIR="${BASE_DIR}/raw_fastq"
OUTPUT_DIR="${BASE_DIR}/trimmomatic_headcrop_15"

mkdir -p "$OUTPUT_DIR"

find "$INPUT_DIR" \
    -type f \
    \( -iname "*.fastq" -o -iname "*.fastq.gz" \) \
    -print0 |
while IFS= read -r -d '' fq; do

    REL_PATH="${fq#${INPUT_DIR}/}"
    REL_DIR=$(dirname "$REL_PATH")
    BASENAME=$(basename "$fq")

    mkdir -p "${OUTPUT_DIR}/${REL_DIR}"

    if [[ "$BASENAME" == *.fastq.gz ]]; then
        STEM="${BASENAME%.fastq.gz}"
    else
        STEM="${BASENAME%.fastq}"
    fi

    OUT_FILE="${OUTPUT_DIR}/${REL_DIR}/${STEM}_trimmed.fastq.gz"

    if [[ -s "$OUT_FILE" ]]; then
        echo "Output exists, skipping: $OUT_FILE"
        continue
    fi

    echo "Processing: $fq"

    trimmomatic SE \
        -threads "$THREADS" \
        "$fq" \
        "$OUT_FILE" \
        HEADCROP:15

done

echo "Trimming complete."
