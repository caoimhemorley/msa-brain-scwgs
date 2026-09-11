# msa-scwgs-cnv

Processing of PicoPLEX Gold-amplified single-cell whole-genome sequencing data from oligodendrocytes and α-synuclein inclusion-bearing cells isolated from multiple system atrophy (MSA) brain tissue.

## Overview

This repository contains project-specific Bash workflows used for processing single-cell whole-genome sequencing data from an MSA brain donor.

The workflow includes trimming of PicoPLEX amplification-derived sequence, sequencing quality control, alignment to the GRCh38 no-alt reference genome, BAM processing, read-group assignment, and duplicate marking.

## Workflow

The workflow includes:

* trimming of PicoPLEX amplification-derived sequence using Trimmomatic
* quality control of sequencing reads using FastQC
* alignment to the GRCh38 no-alt reference genome using Bowtie2
* BAM sorting and indexing using SAMtools
* addition of read groups using Picard
* duplicate marking using Picard

## Repository structure

```text
msa-scwgs-cnv/
├── preprocessing/
│   ├── 01_trimmomatic.sh
│   └── 02_fastqc.sh
├── alignment/
│   ├── 01_bowtie2.sh
│   └── 02_mark_duplicates.sh
├── README.md
└── LICENSE
