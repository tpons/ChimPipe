#!/bin/bash

<<authors
*****************************************************************************
	
	infer_library_type.sh
	
	This file is part of the ChimPipe pipeline 

	Copyright (c) 2014 Bernardo Rodríguez-Martín 
					   Emilio Palumbo 
					   Sarah djebali 
	
	Computational Biology of RNA Processing group
	Department of Bioinformatics and Genomics
	Centre for Genomic Regulation (CRG)
					   
	Github repository - https://github.com/Chimera-tools/ChimPipe
	
	Documentation - https://chimpipe.readthedocs.org/

	Contact - chimpipe.pipeline@gmail.com
	
	Licenced under the GNU General Public License 3.0 license.
******************************************************************************
authors

# Description
##############
# Takes as input a bam file with a set of mapped reads, a reference gene annotation and infers the sequencing library protocol (Unstranded, Mate2_sense & Mate1_sense) used to generate the rna-seq data. It does it by comparing the mapping strand in 1% of the aligments with the strand of the gene the read maps. Finally it produces three numbers: 

# 1) Fraction of reads explained by "1++,1--,2+-,2-+"
# 2) Fraction of reads explained by "1+-,1-+,2++,2--"
# 3) Fraction of reads explained by other combinations

# They give information regarding the library. They contain several strings of three characters, i.e. 1+-, where:
#   Character 1. 1 and 2 are mate1 and mate2 respectively.
#   Character 2. + and - is the strand where the read maps.
#   Character 3. + and - is the strand where the gene in which the read overlaps is annotated.

# You can apply the following rules to infer the used library from this information:

#    NONE. Not strand-specific protocol (unstranded data). Fraction of reads explained by “1++,1–,2+-,2-+” and “1+-,1-+,2++,2–” close to 0.5000 in both cases.

# Strand-specific protocols (stranded data):
#    MATE1_SENSE. Fraction of reads explained by “1++,1–,2+-,2-+” close to 1.0000.
#    MATE2_SENSE. Fraction of reads explained by “1+-,1-+,2++,2–” close to 1.0000.


# usage
#######
# infer_library_type.sh alignments.bam annotation.gff

# Notes
#######
# - Made for using on a 64 bit linux architecture
# - uses awk scripts
# - uses bedtools

# In case the user does not provide any input file, an error message is raised
##############################################################################
if [ ! -n "$1" ] || [ ! -n "$2" ]
then
echo "" >&2
echo "infer_library_type.sh"
echo "" >&2
echo "Takes as input a bam file with a set of mapped reads, a reference gene annotation and infers the sequencing library protocol (Unstranded, Mate2_sense & Mate1_sense) used to generate the rna-seq data. It does it by comparing the mapping strand in 1% of the aligments with the strand of the gene the read maps."
echo "" >&2
echo Usage:  infer_library_type.sh alignments.bam annotation.gff >&2
echo "" >&2
echo "" >&2
exit 1
fi

# GETTING INPUT ARGUMENTS
#########################
bamfile=$1
annot=$2

# Directories 
#############
# Environmental variables 
# rootDir - path to the root folder of ChimPipe pipeline. 
# It is an environmental variable defined and exported in the main script 
awkDir=$rootDir/src/awk

# PROGRAMS
##########
cutgff=$awkDir/cutgff.awk

# START
########
awk -v elt='exon' '$3==elt' $annot | awk -v to=8 -f $cutgff | sort -k1,1 -k4,4 -k5,5 | uniq | bedtools intersect -abam <(samtools view -b -s 1.001 $bamfile) -b stdin -split -bed -wo | awk '{print $4, $6, $19;}' | uniq | awk '{split($1,a,"/"); readCount["total"]++; readCount[a[2]":"$2":"$3]++;}END{fraction1=(readCount["1:+:+"]+readCount["1:-:-"]+readCount["2:+:-"]+readCount["2:-:+"]); fraction2=(readCount["1:+:-"]+readCount["1:-:+"]+readCount["2:+:+"]+readCount["2:-:-"]); other=(readCount["total"]-(fraction1+fraction2)); print (fraction1/readCount["total"]*100), (fraction2/readCount["total"]*100), other;}' 



