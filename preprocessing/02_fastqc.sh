#!/bin/bash -l

#$ -l h_rt=12:00:00
#$ -l mem=8G
#$ -pe smp 4
#$ -N fastqc

set -euo pipefail

conda activate bowtie2

THREADS=4

BASE_DIR="/path/to/project"
INPUT_DIR="${BASE_DIR}/trimmed_fastq"
OUTPUT_DIR="${BASE_DIR}/fastqc_results"

mkdir -p "$OUTPUT_DIR"

find "$INPUT_DIR" \
    -type f \
    \( -name "*.fastq" -o -name "*.fastq.gz" \) \
    -print0 |
while IFS= read -r -d '' fq; do

    echo "Running FastQC on: $fq"

    fastqc \
        --threads "$THREADS" \
        --outdir "$OUTPUT_DIR" \
        "$fq"

done

echo "FastQC complete."
