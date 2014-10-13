# # # # # # # #
# DIRECTORIES #
# # # # # # # #
# temp directory
tmp_dir = ~

# Dmel reference location
dmel_ref = /mnt/nescent/2014-mel-seasonality/pipeline/00_reference/all_Dmel_Release5.fasta

# sample_data directory
dat = /mnt/nescent/2014-mel-seasonality/pipeline/01_sample_data

# mapping directory
02_map_dir = /mnt/nescent/2014-mel-seasonality/pipeline/02_mapping

# divergence directory
03_div_dir = /mnt/nescent/2014-mel-seasonality/pipeline/03_divergence

# popoolation directory
poopolation = ~/bin/popoolation2_1201

# picard-tools directory
picard = ~/bin/picard-tools-1.115

# GATK directory
gatk = ~/bin/GenomeAnalysisTK-3.1-1

# simulans_contamination directory
simulans_contamination = /mnt/nescent/2014-mel-seasonality/pipeline/simulans_contamination

# # # # # # # # # # # # # #
# THREAD AND MEMORY USAGE #
# # # # # # # # # # # # # #
# gatk threads
gatk_threads = 6

# bwa mem threads
bwa_threads = 6

# sambamba threads
sam_threads = 6

# sambamba memory
sam_mem = 8G

# mpileup2sync threads
mp2s_threads = 6

# # # # # # # # #
# SAMPLE NAMES  #
# # # # # # # # #
6d_single_reads = GA_2008_run1 PA_11_2011_run1 PA_7_2011_run1
6d_double_reads = \
GA_2008_run2 \
SC_2010 \
NC_2003 \
PA_11_2009 \
PA_7_2010 \
PA_11_2010 \
PA_10_2011 \
FL_2010_S1 FL_2010_S2 \
ME_2009_S1 ME_2009_S2 \
PA_7_2009_run1 PA_7_2009_run2 \
PA_7_2011_run2 \
PA_11_2011_run2

nescent_reads = BA_2012 MA_2012 NY_2012 PA_2012 VI_2012 WI_2012 VA_2012 SU_2012
nescent_FAT = $(nescent_reads:=_FAT)
nescent_SPT = $(nescent_reads:=_SPT)

all_samples = $(6d_single_reads) $(6d_double_reads) $(nescent_FAT) \
$(nescent_SPT)

# # # # # # # # # # # # # # # # # #
# Simlink bams from mapping step  #
# # # # # # # # # # # # # # # # # #
# Simlink to non-contaminated samples
$(all_samples:=.sorted.rmdup.realign.bam):
	ln -s $(02_map_dir)/$@ $@
$(all_samples:=.sorted.rmdup.realign.bam.bai):
	ln -s $(02_map_dir)/$@ $@

simlink: $(all_samples:=.sorted.rmdup.realign.bam) \
	$(all_samples:=.sorted.rmdup.realign.bam.bai)

# # # # # # # # #
# Create pileup #
# # # # # # # # #
# Parallelized to 4 cores, io is limit
nescent_6d.mpileup: $(all_samples:=.sorted.rmdup.realign.bam) $(all_samples:=.sorted.rmdup.realign.bam.bai)
	samtools view -H $< | grep '\@SQ' | sed 's/^.*SN://g' | cut -f 1 | \
	xargs -I {} -n 1 -P 4 sh -c \
	'samtools mpileup -Q 5 -B -f $(dmel_ref) -r {} $(all_samples:=.sorted.rmdup.realign.bam) > nescent_6d.{}.mpileup'
	cat nescent_6d.*.mpileup > $@

# # # # # # # #
# Create sync #
# # # # # # # #
nescent_6d.sync: nescent_6d.mpileup
	java -ea -Xmx7g -jar $(poopolation)/mpileup2sync.jar --input $^ \
		--output $@ --fastq-type sanger --min-qual 5 \
		--threads $(mp2s_threads)

# # # # # # # # # # # # #
# Detect Contamination  #
# # # # # # # # # # # # #
#  this dataset can now be used to caluclate the allele frequency of the divergent allele in the presumably contaminated dataset. Apart from (unavoidable) false positives in the divergence dataset, contamination should be evenly distributed across the whole genome and only sampling error due to coverage should cause variance in allele frequency. The median of the frequencies of the divergent alleles in the contaminated dataset should represent the approximate level of contamination. These frequencies can be calculated with the script compare_divergence.py This script requires a sync file with the contaminated population(s) and the divergence dataset as inputs. It calculates allele frequencies for the divergent allele specific to species2.
#  E.g. you have a sync file with four populations your commandline should look like this:
nescent_6d.af: nescent_6d.sync
	python $(simulans_contamination)/compare_divergence.py \
	--input $< --div $(03_div_dir)/mel_sim_10x.div \
	--names $(all_samples) --out $@
