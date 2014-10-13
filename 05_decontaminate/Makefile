# # # # # # # #
# Directories #
# # # # # # # #

# temp directory
tmp_dir = ~

# Dmel reference
dmel_ref = ../00_reference/all_Dmel_Release5.fasta

# sample_data directory
dat = ../01_sample_data

# popoolation directory
poopolation = ~/bin/popoolation2_1201

# picard-tools directory
picard = ~/bin/picard-tools-1.115

# simulans_contamination directory
simulans_contamination = ../simulans_contamination

# GATK directory
gatk = ~/bin/GenomeAnalysisTK-3.1-1

# Bam2fastq directory
bm2fq = ~/bin/bam2fastq-1.1.0

# # # # # # # # # # # # # #
# Thread and memory usage #
# # # # # # # # # # # # # #
# bwa mem threads
bwa_threads = 12

# sambamba threads
sam_threads = 4

# mpileup2sync threads
mp2s_threads = 12

# sambamba memory
sam_mem = 4G

# # # # # # # # # # # # # # #
# Combined Reference Genome #
# # # # # # # # # # # # # # #
Dmel_Dsim_reference.fasta.gz: 
	cp ../00_divergence/$@ $@
	bwa index $@

# # # # # # # # # # # # 
# Contaminated Samples #
# # # # # # # # # # # # 

# Contaminated samples with two lanes
# NC_2003 added as a control
contaminated = VA_2012_FAT PA_2012_FAT PA_2012_SPT FL_2010_S2 \
 PA_11_2011_run1 PA_11_2011_run2 NC_2003

# # # # # # # # # # # # #
# Convert bams to fastq #
# # # # # # # # # # # # #
# Simlink to bams and indexes
$(contaminated:=.sorted.rmdup.realign.bam):
	ln -s ../02_mapping/$@ $@

get_bams: $(contaminated:=.sorted.rmdup.realign.bam) \
$(contaminated:=.sorted.rmdup.realign.bam)

cont_dual_reads = $(filter-out PA_11_2011_run1,$(contaminated))

%._1.fastq %._2.fastq: %.sorted.rmdup.realign.bam
	$(bm2fq)/bam2fastq -s -o $*.#.fastq $^

PA_11_2011_run1.fastq: PA_11_2011_run1.sorted.rmdup.realign.bam
	$(bm2fq)/bam2fastq -s -o $@ $^

get_fastq: $(cont_dual_reads:=._1.fastq) PA_11_2011_run1.fastq

# # # # # # # # # # # #
# Competitive Mapping #
# # # # # # # # # # # #

# First map dual reads
$(cont_dual_reads:=.cmap.bam): %.cmap.bam: %._1.fastq %._2.fastq \
	Dmel_Dsim_reference.fasta.gz
	bwa mem -M -t $(bwa_threads) Dmel_Dsim_reference.fasta.gz $< $(word 2,$^) \
		| samtools view -q 5 -Sb - > $@

# Now map single reads
PA_11_2011_run1.cmap.bam: %.cmap.bam: %.fastq \
	Dmel_Dsim_reference.fasta.gz
	bwa mem -M -t $(bwa_threads) Dmel_Dsim_reference.fasta.gz $< \
		| samtools view -q 5 -Sb - > $@

%.sorted.bam: %.bam
	sambamba sort --tmpdir= $(tmp_dir) -t $(sam_threads) -m $(sam_mem) $^ -o $@

cmap_bams: $(contaminated:=.cmap.bam)
sorted_cmap_bams: $(contaminated:=.cmap.sorted.bam)

# # # # # # # # # # # 
# Decontaminate Bams #
# # # # # # # # # # # 

# Index bams
%.bam.bai: %.bam
	sambamba index -t $(sam_threads) $^

indexall: $(contaminated:=.sorted.rmdup.realign.bam.bai)

%.mel.bam: %.sorted.rmdup.realign.bam %.sorted.rmdup.realign.bam.bai %.cmap.sorted.bam
	python $(simulans_contamination)/fix_bam.py \
	--contaminated $*.sorted.rmdup.realign.bam --prefix sim_ --detect $*.cmap.sorted.bam \
	--output $*
	mv $*_mel.bam $*.mel.bam
	mv $*_sim.bam $*.sim.bam
	mv $*_missed.bam $*.missed.bam

fix_all: $(contaminated:=.mel.bam)

# # # # # # # # # # # # # # # # # # # # # # # # # # #
# Extract simulans read names for blacklist filter  #
# # # # # # # # # # # # # # # # # # # # # # # # # # #
%.sim.readnames: %.sim.bam
	samtools view $< | awk -F"\t" '{print $$1}' > $@

readnames: $(contaminated:=.sim.readnames)

# # # # # # # # # # # # # # # # # # # # #
# Test filtering our simulans readnames #
# # # # # # # # # # # # # # # # # # # # #
FL_2010_S2.nosim.bam:
	bamutils filter FL_2010_S2.sorted.rmdup.realign.bam FL_2010_S2.nosim.bam \
	-blacklist FL_2010_S2.sim.readnames

test_filter: FL_2010_S2.nosim.bam

# # # # # # # # #
# Create pileup #
# # # # # # # # #
# Parallelized to 4 cores, io is limit
mel.mpileup: $(contaminated:=.mel.bam)
	samtools view -H $< | grep '\@SQ' | sed 's/^.*SN://g' | cut -f 1 | \
	xargs -I {} -n 1 -P 4 sh -c \
	'samtools mpileup -Q 5 -B -f $(dmel_ref) -r {} $^ > mel.{}.mpileup'
	cat mel.*.mpileup > $@

# # # # # # # #
# Create sync #
# # # # # # # #
mel.sync: mel.mpileup
	java -ea -Xmx7g -jar $(poopolation)/mpileup2sync.jar --input $^ \
		--output $@ --fastq-type sanger --min-qual 5 \
		--threads $(mp2s_threads)

# # # # # # # # # # # # 
# Detect Contamination #
# # # # # # # # # # # # 
#  this dataset can now be used to caluclate the allele frequency of the divergent allele in the presumably contaminated dataset. Apart from (unavoidable) false positives in the divergence dataset, contamination should be evenly distributed across the whole genome and only sampling error due to coverage should cause variance in allele frequency. The median of the frequencies of the divergent alleles in the contaminated dataset should represent the approximate level of contamination. These frequencies can be calculated with the script compare_divergence.py This script requires a sync file with the contaminated population(s) and the divergence dataset as inputs. It calculates allele frequencies for the divergent allele specific to species2.
#  E.g. you have a sync file with four populations your commandline should look like this:


# -----------------------
# Function & variables to
# concatinate names for 
# compare_divergence script

# A literal space and comma
space :=
space +=
comma := ,

# Joins elements of the list in arg 2 with the given separator.
#   1. Element separator.
#   2. The list.
join-with = $(subst $(space),$1,$(strip $2))
# -----------------------


mel.af: mel.sync
	python $(simulans_contamination)/compare_divergence.py \
	--input $< --div ../00_divergence/mel_sim_20x.div \
	--names $(call join-with,$(comma),$(contaminated)) --out $@

#  The results from the above script can be for example visualized as histograms with R:

