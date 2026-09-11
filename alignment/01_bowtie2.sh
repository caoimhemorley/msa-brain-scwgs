#!/bin/bash -l

#$ -l h_rt=24:00:00
#$ -l mem=60G
#$ -pe smp 8
#$ -N bowtie2_picoplex

set -euo pipefail

conda activate bowtie2

THREADS=8

PROJECT_DIR="/path/to/project"
REFERENCE_DIR="/path/to/reference"

BOWTIE2_PREFIX="${REFERENCE_DIR}/human_GRCh38_no_alt_analysis_set"
FASTA="${REFERENCE_DIR}/human_GRCh38_no_alt_analysis_set.fasta"

INPUT_BASE="${PROJECT_DIR}/trimmed_fastq"
OUTPUT_BASE="${PROJECT_DIR}/bowtie2_hg38_no_alt"

mkdir -p "$OUTPUT_BASE"

unset HTS_BLOCK_SIZE || true

timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

have_index() {
    local suffix

    for suffix in bt2l bt2; do
        if [[ -r "${BOWTIE2_PREFIX}.1.${suffix}" &&
              -r "${BOWTIE2_PREFIX}.2.${suffix}" &&
              -r "${BOWTIE2_PREFIX}.3.${suffix}" &&
              -r "${BOWTIE2_PREFIX}.4.${suffix}" &&
              -r "${BOWTIE2_PREFIX}.rev.1.${suffix}" &&
              -r "${BOWTIE2_PREFIX}.rev.2.${suffix}" ]]; then

            IDXSUF="$suffix"
            return 0
        fi
    done

    return 1
}

any_tmp_shards() {
    compgen -G "${BOWTIE2_PREFIX}.*.bt2*.tmp" > /dev/null
}

clean_tmp_shards() {
    rm -f "${BOWTIE2_PREFIX}".*.bt2*.tmp || true
}

rebuild_index() {
    echo "[$(timestamp)] Rebuilding Bowtie2 index from: $FASTA"

    if [[ ! -r "$FASTA" ]]; then
        echo "ERROR: FASTA not found: $FASTA"
        exit 3
    fi

    clean_tmp_shards

    bowtie2-build \
        --threads "$THREADS" \
        "$FASTA" \
        "$BOWTIE2_PREFIX"
}

verify_index() {
    echo "[$(timestamp)] Verifying Bowtie2 index."
    bowtie2-inspect -s "$BOWTIE2_PREFIX" > /dev/null
}

if have_index; then
    echo "[$(timestamp)] Found Bowtie2 index (.${IDXSUF})."

    if any_tmp_shards; then
        echo "[$(timestamp)] Removing leftover temporary index files."
        clean_tmp_shards
    fi
else
    echo "[$(timestamp)] Complete Bowtie2 index not found."

    if any_tmp_shards; then
        echo "[$(timestamp)] Incomplete temporary index files detected."
    fi

    rebuild_index

    if ! have_index; then
        echo "ERROR: Bowtie2 index rebuild failed."
        exit 4
    fi
fi

verify_index

echo "[$(timestamp)] Bowtie2 index OK."

if [[ -n "${TMPDIR:-}" && -d "$TMPDIR" ]]; then
    echo "[$(timestamp)] Copying Bowtie2 index to node-local storage."

    LOCAL_INDEX_DIR="$TMPDIR/bowtie2_index"
    mkdir -p "$LOCAL_INDEX_DIR"

    rsync -a \
        "${BOWTIE2_PREFIX}."*."$IDXSUF" \
        "$LOCAL_INDEX_DIR/"

    BOWTIE2_PREFIX_LOCAL="$LOCAL_INDEX_DIR/$(basename "$BOWTIE2_PREFIX")"
else
    BOWTIE2_PREFIX_LOCAL="$BOWTIE2_PREFIX"
fi

find "$INPUT_BASE" \
    -type f \
    -name "*_R1_trimmed.fastq.gz" \
    -print0 |
while IFS= read -r -d '' R1; do

    R2="${R1/_R1_trimmed.fastq.gz/_R2_trimmed.fastq.gz}"

    if [[ ! -f "$R2" ]]; then
        echo "[$(timestamp)] Missing R2 for: $R1"
        echo "[$(timestamp)] Skipping sample."
        continue
    fi

    SAMPLE_NAME=$(basename "$R1" "_R1_trimmed.fastq.gz")

    OUT_BAM="${OUTPUT_BASE}/${SAMPLE_NAME}_hg38_no_alt_bowtie.sorted.bam"
    TMP_PREFIX="${TMPDIR:-$OUTPUT_BASE}/${SAMPLE_NAME}.tmp"

    if [[ -s "$OUT_BAM" && -s "${OUT_BAM}.bai" ]]; then
        echo "[$(timestamp)] Output already exists, skipping: $SAMPLE_NAME"
        continue
    fi

    echo "[$(timestamp)] Aligning: $SAMPLE_NAME"

    bowtie2 \
        -p "$THREADS" \
        -x "$BOWTIE2_PREFIX_LOCAL" \
        -1 "$R1" \
        -2 "$R2" |
    samtools sort \
        -@ "$THREADS" \
        -m 3G \
        -O bam \
        -T "$TMP_PREFIX" \
        -o "$OUT_BAM"

    samtools index \
        -@ "$THREADS" \
        "$OUT_BAM"

    echo "[$(timestamp)] Completed: $SAMPLE_NAME"
done

echo "[$(timestamp)] Alignment complete."
