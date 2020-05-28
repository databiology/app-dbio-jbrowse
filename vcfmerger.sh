#!/usr/bin/env bash
# JBrowse is a web interface to visualize BAM files.
# Felipe Leza <felipe.leza@databiology.com>
# (C) Databiology 2020

set -euo pipefail

SCRATCH=/scratch
WORKDIR=$SCRATCH/work
MERGERDIR=$SCRATCH/merger
SOURCEDIR=${SCRATCH}/input
RESULTDIR=${SCRATCH}/results
JBROWSE=/www/html/jbrowse
HUMAN_REF=/human_ref
SOY_REF=/soy_ref
PROJECTION=${SCRATCH}/projection.json

# Functions
falseexit () {
   echo "Application failed"
   exit 1
}

# Create and move to WORKDIR
if [ ! -d "$WORKDIR" ]; then mkdir -p "$WORKDIR"; fi

# Create and move to MERGERDIR
if [ ! -d "$MERGERDIR" ]; then mkdir -p "$MERGERDIR"; fi
cd $MERGERDIR

# check projection subjects{samples{extracts{relativepath}}}
has_subjects=$(jq -c '.subjects' ${PROJECTION})

if [ "${has_subjects}" == "null" -o "${has_subjects}" == "[]" ]; then
    echo "Error: input files have not Subjects associated"
    falseexit 
fi

echo "=-> Loop over projection.json ..."
jq -c .subjects[] ${PROJECTION} | while read SUBJECT; do
    INDIVIDUAL_ID=$(echo ${SUBJECT} | jq -er .individualId) || { echo "Error: individualId not found, please check your projection"; falseexit; }
    has_samples=$(echo ${SUBJECT} | jq -c .samples)
    if [ "${has_samples}" != "null" ]; then
        echo ${SUBJECT} | jq -c .samples[] | while read SAMPLE; do
            has_extracts=$(echo ${SAMPLE} | jq -c .extracts)
            if [ "${has_extracts}" != "null" ]; then
                echo ${SAMPLE} | jq -c .extracts[] | while read EXTRACT; do
                    has_resources=$(echo ${EXTRACT} | jq -c '.resources')
                    if [ "${has_resources}" != "null" ]; then
                        EXTRACT_ID=$(echo ${EXTRACT} | jq -er .id) || { echo "Error: extract id not found, please check your projection"; falseexit; }
                        echo "=-> Loop over extract ${EXTRACT_ID}  ..."
                        VCF_FILES=()
                        while read RESOURCE; do
                            NAME=$(echo ${RESOURCE} | jq -er '.name') || { echo "Error: Resource name not found, please check your projection"; falseexit; }
                            if [[ "$NAME" = *.[vV][cC][fF].[gG][zZ] ]]; then
                                RELATIVE_PATH=$(echo ${RESOURCE} | jq -er '.relativePath') || { echo "Error: Resource relativePath not found, please check your projection"; falseexit; }
                                RELATIVE_PATH=$(echo "$RELATIVE_PATH" | perl -pe 's/ /\\ /g')
                                VCF_FILES+=("$SOURCEDIR/$RELATIVE_PATH")
                            fi       
                        done <<< $(echo ${EXTRACT} | jq -c '.resources[]')
                        len=${#VCF_FILES[@]}
                        if [ ${len} -gt 0 ]; then
                            OUTPUTFILENAME="${INDIVIDUAL_ID}_${EXTRACT_ID}_all-chr"
                            CMD="vcf-concat ${VCF_FILES[*]} | bgzip -c > ${OUTPUTFILENAME}.vcf.gz"
                            echo "$CMD"
                            bash -c "$CMD" || { echo "Error concatenating VCF files for individual ${INDIVIDUAL_ID}"; falseexit; }
                            CMD2="vcf-sort --chromosomal-order ${OUTPUTFILENAME}.vcf.gz | bgzip -c > ${OUTPUTFILENAME}.sort.vcf.gz"
                            echo "$CMD2"
                            bash -c "$CMD2" || { echo "Error sorting file ${OUTPUTFILENAME}.vcf.gz for individual ${INDIVIDUAL_ID}"; falseexit; }
                            CMD3="tabix -f ${OUTPUTFILENAME}.sort.vcf.gz"
                            echo "$CMD3"
                            bash -c "$CMD3" || { echo "Error indexing file ${OUTPUTFILENAME}.sort.vcf.gz for individual ${INDIVIDUAL_ID}"; falseexit; }
                            cp "${OUTPUTFILENAME}.sort.vcf.gz" "${OUTPUTFILENAME}.sort.vcf.gz.tbi" "$WORKDIR"
                            cp "${OUTPUTFILENAME}.sort.vcf.gz" "${OUTPUTFILENAME}.sort.vcf.gz.tbi" "$RESULTDIR"
                        fi
                    fi
                done
            fi
        done
    fi
done

ln -s $WORKDIR/* $JBROWSE/data/tracks/

