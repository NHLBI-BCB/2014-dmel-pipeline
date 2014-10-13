#!/bin/bash
# This script parallelizes CRISP by splitting the genome by 
# kill `ps aux | grep CRISP_VC | grep -v grep | awk '{print $2}'`
#
usage="$0 Usage: $0 [-b list of bam files] [-r reference fasta] [-p vcf prefix] [-o outfile]

To make executable: 'chmod 755 CRISP_VC.sh'
Example:

CRISP_VC.sh \
  -b SU_2012_SPT.sorted.rmdup.realign.bam VA_2012_SPT.sorted.rmdup.realign.bam \
  -r /mnt/nescent/dmel_reference/all_dmel.fasta \
  -p nescent_1.0 \
  > /mnt/nescent/trimmed/aligned/nescent_1.0.log 2>&1 &

CRISP_VC.sh \
  -b /mnt/nescent/short/trimmed/aligned/bams.txt \
  -r /mnt/nescent/dmel_reference/all_dmel.fasta \
  -p nescent_1.0 \
  > /mnt/nescent/short/trimmed/aligned/nescent_1.0.log 2>&1 &


"
# base_dir=/mnt/nescent/short/trimmed/aligned
# reference=/mnt/nescent/dmel_reference/all_dmel.fasta
# prefix=nescent_1.0
# bams_list=/mnt/nescent/short/trimmed/aligned/bams.txt


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # 
# Command line options  #
# # # # # # # # # # # # # 

OPTIND=1
# OPTERR=1
while getopts ":b:d:r:p:o:" VALUE "$@" ; do
    if [ "$VALUE" = "b" ] ; then
		bams_list=($OPTARG)
    fi
    if [ "$VALUE" = "r" ] ; then
		reference=$OPTARG
    fi
    if [ "$VALUE" = "p" ] ; then
		prefix=$OPTARG
    fi
    if [ "$VALUE" = "o" ] ; then
		outfile=$OPTARG
    fi		
    # The getopt routine returns a colon when it encounters
    # a flag that should have an argument but doesn't.  It
    # returns the errant flag in the OPTARG variable.
    if [ "$VALUE" = ":" ] ; then
        echo "Flag -$OPTARG requires an argument."
        print "$usage"
        exit 1
    fi
    # The getopt routine returns a question mark when it
    # encounters an unknown flag.  It returns the unknown
    # flag in the OPTARG variable.
    if [ "$VALUE" = "?" ] ; then
        echo "Unknown flag -$OPTARG detected."
        printf "$usage"
        exit 1
    fi
done

# Create list of regions to run.

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create list of regions to run.
int_length=1500000

# 2L
for i in $(seq 1 $int_length 23011544); do
  intervals="$intervals arm_2L:$i-$((i+$int_length-1))"
done

# 2R
for i in $(seq 1 $int_length 21146708); do
  intervals="$intervals arm_2R:$i-$((i+$int_length-1))"
done

# 3L
for i in $(seq 1 $int_length 24543557); do
  intervals="$intervals arm_3L:$i-$((i+$int_length-1))"
done

# 3R
for i in $(seq 1 $int_length 27905053); do
  intervals="$intervals arm_3R:$i-$((i+$int_length-1))"
done

# X
for i in $(seq 1 $int_length 22422827); do
  intervals="$intervals arm_X:$i-$((i+$int_length-1))"
done

# int_length=1000
# # 2L
# for i in $(seq 1 $int_length 10000); do
#   intervals="$intervals arm_2L:$i-$((i+$int_length-1))"
# done
# 
# # 2R
# for i in $(seq 1 $int_length 10000); do
#   intervals="$intervals arm_2R:$i-$((i+$int_length-1))"
# done
# 
# # 3L
# for i in $(seq 1 $int_length 10000); do
#   intervals="$intervals arm_3L:$i-$((i+$int_length-1))"
# done
# 
# # 3R
# for i in $(seq 1 $int_length 10000); do
#   intervals="$intervals arm_3R:$i-$((i+$int_length-1))"
# done
# 
# # X
# for i in $(seq 1 $int_length 10000); do
#   intervals="$intervals arm_X:$i-$((i+$int_length-1))"
# done
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

start=$(date +%s)
echo "

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
Starting CRISP SNP Calling at $(date)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

"

# run crisp in parallel w/ each region
parallel --gnu --jobs 12 --joblog $prefix.jobs.log \
"CRISP-071812/CRISP \
	${bams_list[@]/#/--bam } \
	--ref $reference \
	--poolsize 100 \
	--perms 1000 \
	--filterreads 0 \
	--regions {1} \
	--qvoffset 33 \
	--mbq 10 \
	--mmq 10 \
	--minc 4 \
	--VCF $prefix\_{1}.crisp.vcf \
	> $prefix\_{1}.crisp.log"\
	::: $intervals

end=$(date +%s)
diff=$(( $end - $start ))

echo "

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
CRISP done at $(date) in $(date -u -d @${diff} +"%T") H:M:S
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

"

# # # # # # # # # #
# Fix VCF headers #
# # # # # # # # # #
# VCF tools doesnt' like leading or trailing spaces in description fields...

perl -pi -e 's/(# .*<.*Description=")[ ]*(.*?)[ ]*(".*)/$1$2$3/g' $prefix*.vcf

#  merge subvcf files
vcf-concat $(find $prefix*.crisp.vcf -type f -size +0c) > $outfile

# move vcfs for each region for backup <--- WHY???
mkdir -p vcf_regions
mv $prefix*.crisp.vcf vcf_regions/
mv $prefix*.crisp.log vcf_regions/
