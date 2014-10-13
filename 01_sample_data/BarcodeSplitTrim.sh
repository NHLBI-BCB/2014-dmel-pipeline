#!/bin/bash
# nohup ./00a_BarcodeSplitTrim.sh &> 00a.log &

# Split reads by barcode using fastx tool.
# http://hannonlab.cshl.edu/fastx_toolkit/

# # # # # # # # # #
#  Set variables # 
# # # # # # # # # #

# Output directory
prefix=

# temp directory (CONTENTS WILL BE ERASED)
tmp_dir=tmp

# Fastq files (tab delimited file with popname, read1 and read2 for each sample)
fq_file=$(realpath fq_nescent.txt)

# Barcode key file
bc_file=$(realpath nescent_barcodes.txt)

# # # # # # # # # # # 
#  Make directories # 
# # # # # # # # # #
mkdir -p $prefix
mkdir -p $tmp_dir

# # # # # # # # 
#  Process... # 
# # # # # # # #

# Parse FQFILE as arrays
pop_names=($(cut -f1 $fq_file))
r1=($(cut -f2 $fq_file))
r2=($(cut -f3 $fq_file))

# Check if fastx_barcode_splitter.pl exists
hash fastx_barcode_splitter.pl 2>/dev/null || { echo >&2 "'\
fastx_barcode_splitter.pl' is required but it could not be found. \
Aborting.";exit 1;}

# To install fastx tools
# First install gtextutils
# on fedora/redhat/centos:
#> yum install libgtextutils-devel
# Maybe need to:
#> yum install libgtextutils
# Then go to http://hannonlab.cshl.edu/fastx_toolkit/download.html and download
# latest version.
# unpack, ./configure, make, make install


# # # # # # # # # # # # #
#  Now the actual work  # 
# # # # # # # # # # # # #
for ((i=0; i < ${#pop_names[@]}; i++)) # For i in 0 to # of fastq pairs
do
	# Make temporary directory
	mkdir -p $tmp_dir/${pop_names[i]}
	echo "Splitting ${r1[i]} and ${r2[i]} according to barcode key."
	start=$(date +%s)
	# # # # # # # # # # # # # # # # # # 
	# This passes the pasted fastq pairs to 'fastx_barcode_splitter.pl'
	# which writes the category files to the temporary directory
	paste ${r1[i]} ${r2[i]} | \
	fastx_barcode_splitter.pl --prefix $tmp_dir/${pop_names[i]}/ \
		--bcfile $bc_file --bol --mismatches 1
	# # # # # # # # # # # # # # # # # # 
	# Output info
	end=$(date +%s)
	diff=$(( $end - $start ))
	echo -e "Done in $diff seconds \n"
	
	# # # # # # # # # # # # # # # # # # 
	# For each barcode category
	for file in $tmp_dir/${pop_names[i]}/* # For files in temp directory
	do
		# Skip 'unmatched' category
		echo $file | grep -q "unmatched" && continue
		# Status output
		echo "Trimming barcodes and splitting '$file' by read"
		start=$(date +%s)
		# Make a nice name variable for the population_category
		category_name=$(echo $file |sed "s:$tmp_dir/::" | sed 's/\//_/')
		# # # # # # # # # # # # # # # # # # 
		# This awk script reads each barcode-category file and splits
		# it into r1 and r2 files while trimming 9 bp from the 5' end 
		# of the read
		awk -v r1=$prefix/$category_name"_r1.fastq" \
			-v r2=$prefix/$category_name"_r2.fastq" \
				'BEGIN { FS = "\t" } ; { 
				       if (NR % 2 == 0){
  				         print(substr($1, 10)) > r1
  				         print(substr($2, 10)) > r2
					   } else{
				         print($1) > r1
				         print($2) > r2
				       }
				   }' $file
		 # More status output
	 	end=$(date +%s)
	 	diff=$(( $end - $start ))
	 	echo -e "Done in $diff seconds \n"
	done
	# Delete the temporary directory between each population to save disk 
	# space
	rm -rf $tmp_dir
done