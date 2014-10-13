# # # # # # # #
# Directories #
# # # # # # # #
# temp directory
tmp_dir = ~

# Dmel reference location
dmel_ref = ../00_reference/all_Dmel_Release5.fasta

# sample_data directory
dat = ../01_sample_data

# popoolation directory
poopolation = ~/bin/popoolation2_1201

# picard-tools directory
picard = ~/bin/picard-tools-1.115

# GATK directory
gatk = ~/bin/GenomeAnalysisTK-3.1-1

# simulans_contamination directory
simulans_contamination = ../simulans_contamination

# # # # # # # # # # # # # #
# Thread and memory usage #
# # # # # # # # # # # # # #
# gatk threads
gatk_threads = 6

# bwa mem threads
bwa_threads = 6

# sambamba threads
sam_threads = 6

# sambamba memory
sam_mem = 8G

# # # # # # # # #
# Sample names  #
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

# # # # # # # # # # # #
# Map reads           #
# Fastq files -> bams #
# # # # # # # # # # # #
# Map single end reads
$(6d_single_reads:=.bam): %.bam:
	bwa mem -M -t $(bwa_threads) -R '@RG\tID:$*\tSM:$*/tLB:$*/tPL:ILLUMINA' \
	$(dmel_ref) $(dat)/$*_r1.fastq | samtools view -Sb - > $@

# Map dual ended reads
$(6d_double_reads:=.bam) $(nescent_FAT:=.bam) $(nescent_SPT:=.bam): \
%.bam:
	bwa mem -M -t $(bwa_threads) -R '@RG\tID:$*\tSM:$*/tLB:$*/tPL:ILLUMINA' \
	$(dmel_ref) $(dat)/$*_r1.fastq $(dat)/$*_r2.fastq | samtools view -Sb - > $@

.SECONDARY: $(all_samples:=.bam) $(all_samples:=.sorted.bam) \
	$(all_samples:=.sorted.bam.bai) \
	$(all_samples:=.sorted.rmdup.bam) \
	$(all_samples:=.sorted.rmdup.bam.bai)

# Sort bams
%.sorted.bam: %.bam
	sambamba sort --tmpdir= $(tmp_dir) -t $(sam_threads) -m $(sam_mem) $^ -o $@
	
# # # # # # # # # # # # # # # # # #
# Mark and remove duplicate reads #
# # # # # # # # # # # # # # # # # #
# Index bams
%.bam.bai: %.bam
	sambamba index -t $(sam_threads) $^

# Remove pcr duplicates
%.sorted.rmdup.bam: %.sorted.bam %.sorted.bam.bai
	sambamba markdup --overflow-list-size 600000 -r -t$(sam_threads) $< $@

rmdups: $(all_samples:=.sorted.rmdup.bam)

# # # # # # # # # # #
# Indel realignment #
# # # # # # # # # # #
# Create GATK reference index
$(dmel_ref:.fasta=.dict):
	java -Xmx2g -jar $(picard)/CreateSequenceDictionary.jar \
	R=$(dmel_ref) O=$@

$(dmel_ref:=.fai):
	samtools faidx $(dmel_ref)

# indel realignment
# Need to fix some bam quality scores, others fine
# These bams do not need the fix_misencoded_quality_score flag, and RealignerTargetCreator will fail w/ the flag.
good_scores = $(nescent_FAT) $(nescent_SPT) PA_10_2011
$(good_scores:=.sorted.rmdup.bam.intervals): %.sorted.rmdup.bam.intervals: \
	%.sorted.rmdup.bam %.sorted.rmdup.bam.bai $(dmel_ref:.fasta=.dict) \
	$(dmel_ref:=.fai)
	java -Xmx10g -jar $(gatk)/GenomeAnalysisTK.jar \
	-T RealignerTargetCreator \
	-nt $(gatk_threads) \
	-I $< \
	-R $(dmel_ref) \
	-o $@

# These reads *do* need the fix_mis... flag...
6d_all = $(6d_double_reads) $(6d_single_reads)
fix_scores = $(filter-out PA_10_2011, $(6d_all))
$(fix_scores:=.sorted.rmdup.bam.intervals): %.sorted.rmdup.bam.intervals: \
	%.sorted.rmdup.bam %.sorted.rmdup.bam.bai $(dmel_ref:.fasta=.dict) \
	$(dmel_ref:=.fai)
	java -Xmx10g -jar $(gatk)/GenomeAnalysisTK.jar \
	-T RealignerTargetCreator \
	--fix_misencoded_quality_scores \
	-nt $(gatk_threads) \
	-I $< \
	-R $(dmel_ref) \
	-o $@

debug: GA_2008_run1.sorted.rmdup.bam.intervals

intervals: $(all_samples:=.sorted.rmdup.bam.intervals)

$(good_scores:=.sorted.rmdup.realign.bam):%.sorted.rmdup.realign.bam: %.sorted.rmdup.bam \
	%.sorted.rmdup.bam.intervals
	java -Xmx8g -jar $(gatk)/GenomeAnalysisTK.jar \
	-T IndelRealigner \
	-I $< \
	-R $(dmel_ref) \
	-targetIntervals $*.sorted.rmdup.bam.intervals \
	-o $@

$(fix_scores:=.sorted.rmdup.realign.bam):%.sorted.rmdup.realign.bam: %.sorted.rmdup.bam \
	%.sorted.rmdup.bam.intervals
	java -Xmx8g -jar $(gatk)/GenomeAnalysisTK.jar \
	-T IndelRealigner \
	--fix_misencoded_quality_scores \
	-I $< \
	-R $(dmel_ref) \
	-targetIntervals $*.sorted.rmdup.bam.intervals \
	-o $@

realign: $(all_samples:=.sorted.rmdup.realign.bam) \
	$(all_samples:=.sorted.rmdup.realign.bam.bai)

.PRECIOUS: %.sorted.bam.bai %.sorted.rmdup.bam.index %.sorted.rmdup.bam.intervals

.SECONDARY: $(all_samples:=.sorted.bam) $(all_samples:=.sorted.bam.bai) \
	$(all_samples:=.sorted.rmdup.bam) $(all_samples:=.sorted.rmdup.realign.bam) \
	$(all_samples:=.sorted.rmdup.bam.intervals) \
	$(all_samples:=.sorted.rmdup.realign.bam) nescent_6d.mpileup nescent_6d.sync \
	nescent_6d.af
