#!/usr/bin/env bash
# JBrowse is a web interface to visualize BAM files.
# Felipe Leza <felipe.leza@databiology.com>
# (C) Databiology 2020

set -euo pipefail

SCRATCH=/scratch
SOURCEDIR=${SCRATCH}/inputresources
RESULTDIR=${SCRATCH}/results
JBROWSE=/www/html/jbrowse
HUMAN_REF_GRCh38=/GRCh38
HUMAN_REF_GRCh37=/GRCh37
SOY_REF=/soy_ref

REF=/www/html/jbrowse/data

# Functions
falseexit () {
   echo "Application failed"
   exit 1
}

TASK=$(jq -r '.["APPLICATION"] .concat_sort_index' $SCRATCH/parameters.json)
if [ "$TASK" == "true" ]; then
    # read projection.json and check individual metadata
    /usr/local/bin/vcfmerger.sh
else
    # input files are ready in SOURCEDIR
    ln -s $SOURCEDIR/* $JBROWSE/data/tracks/
fi


cd $JBROWSE/data/

BW_FLAG="false"
for BW in ./tracks/*.bw; do
    if [ -e "$BW" ]; then
        SAMPLE=$(basename "$BW")
        SAMPLE="${SAMPLE%%.*}"
        {
            echo
            echo "[ tracks.$SAMPLE ]"
            echo "storeClass     = JBrowse/Store/SeqFeature/BigWig"
            echo "category       = RNA-seq"
            echo "urlTemplate    = tracks/$(basename $BW)"
            echo "type           = JBrowse/View/Track/Wiggle/XYPlot"
            echo "key            = RNA-seq Test Data $SAMPLE"
            echo "autoscale      = local"
        } >> 'tracks.conf'
        BW_FLAG="true"
    fi
done

for MT in ./tracks/*.cg; do
    FILENAME=$(basename "$MT")
    FNAME="${FILENAME%.*}"
    if [ -e ./tracks/"${FNAME}".chg ] && [ -e ./tracks/"${FNAME}".chh ]; then
        SAMPLE=$(basename "$MT")
        SAMPLE="${SAMPLE%%.*}"
        {
            echo
            echo "[ tracks.$SAMPLE ]"
            echo "storeClass     = MethylationPlugin/Store/SeqFeature/MethylBigWig"
            echo "category       = DNAMethylation"
            echo "urlTemplate    = tracks/$FNAME"
            echo "type           = MethylationPlugin/View/Track/Wiggle/MethylPlot"
            echo "key            = RNA-seq Data $SAMPLE"
            echo "contexts       = ['cg', 'chg', 'chh']"
            echo "isAnimal       = false"
        } >> 'tracks.conf'
    fi
done

BAM_FLAG="false"
for BAM in ./tracks/*.bam; do
    if [ -e "$BAM" ]; then
        if [ ! -e "$BAM.bai" ]; then
            echo "No index was found matching this $BAM file. Creating and index for it!"
            samtools index "$BAM" || { echo "Error creating index file for $BAM"; falseexit; }
        fi
        SAMPLE=$(basename "$BAM" .bam)
        {
            echo
            echo "[ tracks.$RANDOM ]"
            echo "storeClass     = JBrowse/Store/SeqFeature/BAM"
            echo "urlTemplate    = $BAM"
            echo "baiUrlTemplate = $BAM.bai"
            echo "category       = NGS"
            echo "type           = JBrowse/View/Track/Alignments2"
            echo "key            = BAM alignments from sample $SAMPLE"
        } >> 'tracks.conf'
        BAM_FLAG="true"
    fi
done

VCFZ_FLAG="false"
for VCFZ in ./tracks/*.vcf.gz; do
    if [ -e "$VCFZ" ]; then
        if [ ! -e "$VCFZ.tbi" ]; then
            echo "No index was found matching this $VCFZ file. Creating and index for it!"
            tabix "$VCFZ" || { echo "Error creating index file for $VCFZ"; falseexit; }
        fi
        SAMPLE=$(basename "$VCFZ" .vcf.gz)
        {
            echo
            echo "[ tracks.$RANDOM ]"
            echo "storeClass     = JBrowse/Store/SeqFeature/VCFTabix"
            echo "urlTemplate    = $VCFZ"
            echo "category       = VCF"
            echo "type           = JBrowse/View/Track/CanvasVariants"
            echo "key            = SNPs from sample $SAMPLE"

        } >> 'tracks.conf'
        VCFZ_FLAG="true"
    fi
done

if [ "$BAM_FLAG" == "false" ] && [ "$VCFZ_FLAG" == "false" ] && [ "$BW_FLAG" == "false" ]; then
   echo "BAM, BW or VCF file(s) not found"
   falseexit
fi

GENOME=$(jq -r '.["APPLICATION"] .genome' $SCRATCH/parameters.json)
case $GENOME in
    GRCh37)
        echo "Using Genome GRCh37"
        if [ ! -e "$HUMAN_REF_GRCh37/Homo_sapiens.$GENOME.fa" ]; then
          echo "Reference not found, please report the issue"
          falseexit
        fi
        REF="$HUMAN_REF_GRCh37/Homo_sapiens.$GENOME.fa"

        if [ ! -e "$HUMAN_REF_GRCh37/Homo_sapiens.$GENOME.87.gff3" ]; then
          echo "${GENOME}.gff3 file not found, please report the issue"
          falseexit
        fi
        GFF="$HUMAN_REF_GRCh37/Homo_sapiens.$GENOME.87.gff3"
        ;;
    GRCh38)
        echo "Using Genome GRCh38"
        if [ ! -e "$HUMAN_REF_GRCh38/$GENOME.97.fa" ]; then
            echo "Reference not found, please report the issue"
            falseexit
        fi
        REF="$HUMAN_REF_GRCh38/$GENOME.97.fa"
        if [ ! -e "$HUMAN_REF_GRCh38/$GENOME.97.gff3" ]; then
          echo "${GENOME}.97.gff3 file not found, please report the issue"
          falseexit
        fi
        GFF="$HUMAN_REF_GRCh38/$GENOME.97.gff3"
        ;;
    SOY)
        REF=$(echo $SOY_REF/*.fa)
        echo "Using Soybean Genome"
        if [ ! -e "$REF" ]; then
            echo "Reference not found, please report the issue"
            falseexit
        fi
        GFF=$(echo $SOY_REF/*.gff3)
        if [ ! -e "$GFF" ]; then
          echo "gff3 file not found, please report the issue"
          falseexit
        fi
        ;;
    *)
        echo "Genome '$GENOME' is not recognized, please use GRCh37, GRCh38 or SOY"
        falseexit
        ;;
esac

ln -s "$REF" "$JBROWSE"/data/
ln -s "$GFF" "$JBROWSE"/data/

REF=$(echo "$JBROWSE"/data/*.fa)
GFF=$(echo "$JBROWSE"/data/*.gff3)

cd $JBROWSE/
# web server shows a wait page until all subtasks finish
ln -s wait.html index.html
echo "Running web server"
#/etc/init.d/nginx start
./serve 2> $RESULTDIR/jbrowse-log.txt &

echo "preparing reference $REF"
CMD="$JBROWSE/bin/prepare-refseqs.pl --fasta $REF"
echo "$CMD"
$CMD || falseexit

echo "preparing gene track $GFF"
CMD="$JBROWSE/bin/flatfile-to-json.pl --gff $GFF --trackType CanvasFeatures --trackLabel refGene"
echo "$CMD"
$CMD || falseexit

cd $JBROWSE
echo "updating tracks"
CMD="$JBROWSE/bin/generate-names.pl -v"
echo "$CMD"
$CMD || falseexit

# web server shows the Jbrowse index page
echo "Running Jbrowse"
rm index.html && ln -s main.html index.html

sleep infinity

