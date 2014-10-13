# # # # # # # #
# Directories #
# # # # # # # #

# temp directory
tmp_dir = ~

# Dmel reference
dmel_ref = ../00_reference/all_Dmel_Release5.fasta

# Dsim reference
dsim_ref = ../dsimV2-Mar2013-Genbank.fasta.gz

# popoolation directory
poopolation = ~/bin/popoolation2_1201

# picard-tools directory
picard = ~/bin/picard-tools-1.115

# simulans_contamination directory
simulans_contamination = ../simulans_contamination

# # # # # # # # # # # # # #
# Thread and memory usage #
# # # # # # # # # # # # # #
# bwa mem threads
bwa_threads = 6

# mpileup2sync threads
mp2s_threads = 6

# sambamba threads
sam_threads = 6

# sambamba memory
sam_mem = 8G

# # # # # # # # #
# Main targets  #
# # # # # # # # #
all: mel_sim_5x.div mel_sim_10x.div mel_sim_15x.div\
	mel_sim_20x.div

# # # # # # # # # # # # # # # # # #
# Download dmel reads & sim reads #
# # # # # # # # # # # # # # # # # #

# Get dmel dgrp data
dgrp = SRR834545 SRR835077

SRR834545.fastq.gz:
	curl -O -sS http://ftp-trace.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/sra\
/SRR/SRR834/SRR834545/SRR834545.sra
	fastq-dump --gzip ::: SRR834545.sra

SRR835077.fastq.gz:
	curl -O -sS http://ftp-trace.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/sra/\
SRR/SRR835/SRR835077/SRR835077.sra
	fastq-dump --gzip ::: SRR835077.sra

# Random simulans from http://hpc.oit.uci.edu/~krthornt/dsim_genomic_reads/
# Two isofemale lines details here: http://arxiv.org/pdf/1401.7371v2.pdf 
krthornt = MD15_02_09_11_71 NS33_02_19_2011_75

MD15_02_09_11_71.L.fastq.gz:
	curl -sS -o MD15_02_09_11_71.L.fastq.gz \
	http://hpc.oit.uci.edu/~krthornt/dsim_genomic_reads/\
MD15_02_09_11_71_1.fastq.gz	
MD15_02_09_11_71.R.fastq.gz:
	curl -sS -o MD15_02_09_11_71.R.fastq.gz -sS \
	http://hpc.oit.uci.edu/~krthornt/dsim_genomic_reads/\
MD15_02_09_11_71_2.fastq.gz
NS33_02_19_2011_75.L.fastq.gz:
	curl -sS -o NS33_02_19_2011_75.L.fastq.gz \
	http://hpc.oit.uci.edu/~krthornt/dsim_genomic_reads/\
NS33_02_19_2011_75_1.fastq.gz
NS33_02_19_2011_75.R.fastq.gz:
	curl -sS -o NS33_02_19_2011_75.R.fastq.gz \
	http://hpc.oit.uci.edu/~krthornt/dsim_genomic_reads/\
NS33_02_19_2011_75_2.fastq.gz

# East coast simulans from Heather Machado. I just picked a few ind. with high 
# coverage
east_coast_sim = B_15_1 A_14_1 E_15_1 E_16_1 E_17_1 E_18_1 I_14_1 I_15_1

$(east_coast_sim:=.L.fastq) $(east_coast_sim:=.R.fastq): %.fastq:
	@echo 'Contact Heather Machado to get $@'
	cp /mnt/simulans/MachadoSequenceData/EastCoastSim/$*.fastq $*.fastq

%.gz: %
	gzip $<

.INTERMEDIATE: $(east_coast_sim:=.L.fastq) $(east_coast_sim:=.R.fastq)

ecs: $(east_coast_sim:=.L.fastq.gz) $(east_coast_sim:=.R.fastq.gz)
# # # # # # # # # # # # # # # # #
# Map reads to reference genome #
# # # # # # # # # # # # # # # # #
all_populations = $(dgrp) $(krthornt) $(east_coast_sim)

# Mag single end reads
$(dgrp:=.bam): %.bam: %.fastq.gz
	bwa mem -M -t $(bwa_threads) $(dmel_ref) $^ \
		| samtools view -q 20 -Sb - > $@

# Map dual ended reads
$(krthornt:=.bam) $(east_coast_sim:=.bam): %.bam: %.L.fastq.gz %.R.fastq.gz
	bwa mem -M -t $(bwa_threads) $(dmel_ref) $^ \
		| samtools view -q 20 -Sb - > $@

# Sort bams
%.sorted.bam: %.bam
	sambamba sort --tmpdir= $(tmp_dir) -t$(sam_threads) -m$(sam_mem) $^ -o $@

# Index bams
%.bam.bai: %.bam
	sambamba index -t$(sam_threads) $^

sorted_bams: $(all_populations:=.sorted.bam)

# Remove pcr duplicates
%.sorted.rmdup.bam: %.sorted.bam %.sorted.bam.bai
	sambamba markdup -r -t$(sam_threads) $< $@

rmdup_bams: $(all_populations:=.sorted.rmdup.bam)

# Combine east coast sim into one bam/population
ecs_combo.sorted.rmdup.bam: $(east_coast_sim:=.sorted.rmdup.bam)
	sambamba merge -t$(sam_threads) $@ $^

# # # # # # # # #
# Intermediates #
# # # # # # # # #
# These can eventually be deleted, but better to do so manually.
.SECONDARY: $(all_populations:=.bam) $(all_populations:=.sorted.bam) \
	$(all_populations:=.sorted.bam.bai)
	
# # # # # # # # #
# Create pileup #
# # # # # # # # #
	
mel_sim.mpileup: $(all_populations:=.sorted.rmdup.bam) $(all_populations:=.sorted.rmdup.bam.bai)
	samtools view -H $< | grep '\@SQ' | sed 's/^.*SN://g' | cut -f 1 | \
	xargs -I {} -n 1 -P 4 sh -c \
	'samtools mpileup -Q 5 -B -f $(dmel_ref) -r {} \
	$(all_populations:=.sorted.rmdup.bam) > mel_sim.{}.mpileup'
	cat mel_sim.*.mpileup > $@

# # # # # # # #
# Create sync #
# # # # # # # #
mel_sim.sync: mel_sim.mpileup
	java -ea -Xmx7g -jar $(poopolation)/mpileup2sync.jar --input $^ \
		--output $@ --fastq-type sanger --min-qual 20 \
		--threads $(mp2s_threads)

# # # # # # # # # # #
# Create divergence #
# # # # # # # # # # #
# The script detect_divergence.py extracts divergent positions and stores the 
# divergent alleles as well as the synced populations in the output. You have 
# to define the populations of the two different species ( --species1, 
# --species2) as well as the minor allele count threshold for each of the 
# populations per species (--species1-mincount, --species2-mincount ). 
# Additionally you have to define a global min-coverage and max-coverage 
# threshold. Note, that it is assumed that species1 Pool-Seq data is 
# contaminated with reads of species2. Therefore, if you have for example three 
# populations of melanogaster (1,2,3) and three of simulans (4,5,6) , your 
# command line should look like this:
# python ~/simulans_contamination/detect_divergence.py --input input.sync 
#  --output sim_mel.div --species1 1,2,3 --species2 4,5,6 --species1-mincount 
#  1,1,1 --species2-mincount 1,1,1 --min-coverage 50 --max-coverage 200

mel_sim_50x.div: mel_sim.sync
	python $(simulans_contamination)/detect_divergence.py --input $^ \
	--output $@ --species1 1,2 --species2 3,4,5 \
	--species1-mincount 1,1 --species2-mincount 1,1,1 \
	--min-coverage 50 --max-coverage 200

mel_sim_20x.div: mel_sim.sync
	python $(simulans_contamination)/detect_divergence.py --input $^ \
	--output $@ --species1 1,2 --species2 3,4,5 \
	--species1-mincount 1,1 --species2-mincount 1,1,1 \
	--min-coverage 20 --max-coverage 200

mel_sim_15x.div: mel_sim.sync
	python $(simulans_contamination)/detect_divergence.py --input $^ \
	--output $@ --species1 1,2 --species2 3,4,5 \
	--species1-mincount 1,1 --species2-mincount 1,1,1 \
	--min-coverage 15 --max-coverage 200

mel_sim_10x.div: mel_sim.sync
	python $(simulans_contamination)/detect_divergence.py --input $^ \
	--output $@ --species1 1,2 --species2 3,4,5 \
	--species1-mincount 1,1 --species2-mincount 1,1,1 \
	--min-coverage 10 --max-coverage 200

mel_sim_5x.div: mel_sim.sync
	python $(simulans_contamination)/detect_divergence.py --input $^ \
	--output $@ --species1 1,2 --species2 3,4,5 \
	--species1-mincount 1,1 --species2-mincount 1,1,1 \
	--min-coverage 5 --max-coverage 200

# # # # # # # # # # # #
# Competitive Mapping #
# # # # # # # # # # # #
# Test whether competitive mapping works

# Create dual-genome
# Mark sim genome with prefix
Dsim_prefixed.fasta.gz: $(dsim_ref)
	sed 's/>/>sim_/g' $(^:.gz=) > $(@:.gz=)
	gzip $(@:.gz=)

#  concatenate both genomes:
Dmel_Dsim_reference.fasta.gz: $(dmel_ref) Dsim_prefixed.fasta.gz
	cat $^ > $@
	bwa index $@

create_comp_reference: Dmel_Dsim_reference.fasta.gz

# Map contaminated to combined reference genome

# Mag single end reads
$(dgrp:=.comp.bam): %.comp.bam: %.fastq.gz
	bwa mem -M -t $(bwa_threads) Dmel_Dsim_reference.fasta.gz $^ \
		| samtools view -q 20 -Sb - > $@

# Map dual ended reads
$(krthornt:=.comp.bam) $(east_coast_sim:=.comp.bam): %.comp.bam: %.L.fastq.gz %.R.fastq.gz
	bwa mem -M -t $(bwa_threads) Dmel_Dsim_reference.fasta.gz $^ \
		| samtools view -q 20 -Sb - > $@

#  E.g. you have a contaminated BAM file named contamination.bam and want to separate mel and sim reads based on the mapping to both genomes (assortative_mapping.sam), your commandline should look like this. Note that the prefix corresponds to the prefix you have added to all chromosomes of the "contaminant" reference before:

%_mel.bam: %.sorted.rmdup.bam %.sorted.rmdup.bam.bai %.comp.sorted.bam
	python $(simulans_contamination)/fix_bam.py \
	--contaminated $*.sorted.rmdup.bam --prefix sim_ --detect $*.comp.sorted.bam \
	--output $*


#  you will get three outputs clean_mel.bam, clean_sim.bam and clean_missed.bam. clean_mel.bam can now be used to create new mpileup and sync files. After that compare_divergence.py can be used again on the sync file to test how well the sweeping worked.

final: SRR834545_mel.bam

.SECONDARY: $(all_populations:=.comp.sorted.bam) \
	$(all_populations:=.sorted.rmdup.bam.bai)

