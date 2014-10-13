#!/bin/bash
# nohup ./00b_Copy6dReads.sh &> 00b.log &

# Creates symbolic links to the 6d reads.

# Output directory
prefix=

# Fastq files (tab delimited file with read1 and read2 for each sample)
fq_file=$(realpath fq_6Dimensions.txt)

mkdir -p $prefix

# Parse FQFILE as arrays
pop_names=($(cut -f1 $fq_file))
r1=($(cut -f2 $fq_file))
r2=($(cut -f3 $fq_file))

for ((i=0; i < ${#pop_names[@]}; i++)) # For i in 0 to # of fastq pairs
do
	echo "Linking ${r1[i]} and ${r2[i]} as\n\
${pop_names[i]}_r1.fastq and ${pop_names[i]}_r2.fastq"
	start=$(date +%s)
	if [ "${r1[i]}" != "NULL" ] && [ ! -L "${r1[i]}" ]; then
	ln -s ${r1[i]} $prefix/${pop_names[i]}_r1.fastq
  fi
	if [ "${r2[i]}" != "NULL" ] && [ ! -L "${r2[i]}" ]; then
		ln -s ${r2[i]} $prefix/${pop_names[i]}_r2.fastq
	fi
	end=$(date +%s)
 	diff=$(( $end - $start ))
 	echo -e "Done in $diff seconds \n"
done