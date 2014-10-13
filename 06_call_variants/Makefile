# e.g. nohup make sorted_bams &
# e.g. nohup make -k -j2 realign &
# e.g. make --just-print sorted_bams
# e.g. make --just-print realign
#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  # 
# # # # # # # #
# DIRECTORIES #
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

# # # # # # # # 
# SAMPLE NAMES #
# # # # # # # # 
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
# Contaminated Samples #
# # # # # # # # # # # # 
contaminated = VA_2012_FAT PA_2012_FAT PA_2012_SPT FL_2010_run2 \
PA_11_2011_run1 PA_11_2011_run2
not_contaminated = $(filter-out $(contaminated), $(all_samples))

# # # # # # # # # # # # # # # # # 
# Simlink bams from mapping step #
# # # # # # # # # # # # # # # # # 
# Simlink to non-contaminated samples
$(not_contaminated:=.sorted.rmdup.realign.bam):
	ln -s ../02_mapping/$@ $@
$(not_contaminated:=.sorted.rmdup.realign.bam.bai):
	ln -s ../02_mapping/$@ $@

# Symlink to bams that have been decontaminated
$(contaminated:=.sorted.rmdup.realign.bam): %.sorted.rmdup.realign.bam:
	ln -s ../05_decontaminate/$*.mel.bam $@
# Index decontaminated bams
$(contaminated:=.sorted.rmdup.realign.bam.bai): \
	%.sorted.rmdup.realign.bam.bai: %.sorted.rmdup.realign.bam
	sambamba index -t $(sam_threads) $^

symlink: $(all_samples:=.sorted.rmdup.realign.bam) \
	$(all_samples:=.sorted.rmdup.realign.bam.bai)

# # # # # # # # # # # # # # # # # # # 
# Merge Samples from same population #
# # # # # # # # # # # # # # # # # # # 
# Get list of all population samples (strip 'run1' and 'run2')
all_pop_temp = $(patsubst %_run1,%,$(patsubst %_run2,%,$(all_samples)))
# remove duplicate population names
all_populations = $(sort $(all_pop_temp))

# What populations need to be merged? I.e. the pops that had multiple runs
tbm = GA_2008 PA_11_2011 PA_7_2009 PA_7_2011

# Merge
$(tbm:=.sorted.rmdup.realign.bam): %.sorted.rmdup.realign.bam: \
	%_run1.sorted.rmdup.realign.bam %_run2.sorted.rmdup.realign.bam
	sambamba merge -t$(sam_threads) $@ $^

# Index merged bams
$(tbm:=.sorted.rmdup.realign.bam.bai): \
	%.sorted.rmdup.realign.bam.bai: %.sorted.rmdup.realign.bam
	sambamba index -t $(sam_threads) $^


merge: $(tbm:=.sorted.rmdup.realign.bam)

debug: $(all_populations:=.sorted.rmdup.realign.bam)

# # # # # # # # # # # # 
# Call SNPs with CRISP #
# # # # # # # # # # # # 
# vcCRISP.sh is a script that parallelizes CRISP. We use version CRISP-071812
# Because newer versions of CRISP provide weird allele counts that don't make 
# sense... Since, for this analyses we are only interested in common(ish)
# variants we think CRISP-071812 is fine.
6d_nescent_2_0.raw.vcf: $(all_populations:=.sorted.rmdup.realign.bam) \
	$(all_populations:=.sorted.rmdup.realign.bam.bai)
	./vcCRISP.sh -b  "$(all_populations:=.sorted.rmdup.realign.bam)" -d . -r $(dmel_ref) -p 6d_nescent -o $@
