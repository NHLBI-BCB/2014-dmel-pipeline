# # # # # # # # # #
# SymLink raw VCF #
# # # # # # # # # #
%.raw.vcf:
	ln -s ../06_call_variants/$@ $@

raw: 6d_nescent_2_0.raw.vcf

# # # # # # # #
# Process VCF #
# # # # # # # #
# CRISP adds an extra column to the VCF output that should not be there. It
# only adds the column to SNV variants, not to insertion+SNV variants. This awk
# script fixes things.
%.fixed.vcf: %.raw.vcf
	awk -F"\t" -f fix.awk < $< > $@

%.sorted.vcf: %.vcf
	vcf-sort $< > $@

fixed: 6d_nescent_2_0.fixed.vcf 6d_nescent_2_0.fixed.sorted.vcf

# remove SNPs in repetative regions
repetitive_regions.bed:
	cat /mnt/Alan/new_alignments/vcf2/repetative/rm.edit.bed | \
	sed 's/^/arm_/' > $@

%.fixed.sorted.norepeats.vcf: %.fixed.sorted.vcf repetitive_regions.bed
	vcftools --vcf $< --out $* \
	--exclude-bed repetitive_regions.bed \
	--recode --recode-INFO-all
	mv $*.recode.vcf $*.fixed.sorted.norepeats.vcf 

norepeats: 6d_nescent_2_0.fixed.sorted.norepeats.vcf
	
# Filter out insertions and deletions.
%.fixed.norepeats.snps.vcf: %.fixed.sorted.norepeats.vcf
	vcftools --vcf $< --remove-indels --recode --recode-INFO-all --out $*.snps
	mv $*.snps.recode.vcf $@

%.fixed.norepeats.indels.vcf: %.fixed.sorted.norepeats.vcf
	vcftools --vcf $< --keep-only-indels --recode --recode-INFO-all \
	--out $*.indels
	mv $*.indels.recode.vcf $@

snp_indel: 6d_nescent_2_0.fixed.norepeats.snps.vcf 6d_nescent_2_0.fixed.norepeats.indels.vcf

# Add closest indel info to SNPs vcf.
%.fixed.norepeats.snps.sorted.d2i.vcf: %.fixed.norepeats.snps.sorted.vcf %.fixed.norepeats.indels.sorted.vcf
	closestBed -d -t first -a $< -b $(word 2,$^) | \
	awk '{for(i=1; i<=7; i++) printf $$i"\t"; printf "D2I="$$NF";"$$8"\t"$$9"\t"; for(i=10; i<=(NF-1)/2; i++) {printf $$i; if(i<(NF-1)/2) printf "\t"; if(i==(NF-1)/2) printf "\n"}}'\
	 >> $@

d2i: 6d_nescent_2_0.fixed.norepeats.snps.sorted.d2i.vcf

# run through allele count conversion script; this calculates average allele
# freq and converts population columns to AF:DP format
%.converted.vcf: %.vcf
	awk -F"\t" -f convert.awk < $< > $@

converted: 6d_nescent_2_0.fixed.norepeats.snps.sorted.d2i.converted.vcf 6d_nescent_2_0.fixed.norepeats.indels.sorted.converted.vcf

# # # # # # # #
# Add Header  #
# # # # # # # #
%.snps.final.vcf: %.fixed.norepeats.snps.sorted.d2i.converted.vcf
	cat VCF.header > $@
	cat $< >> $@

%.indels.final.vcf: %.fixed.norepeats.indels.sorted.converted.vcf
	cat VCF.header > $@
	cat $< >> $@

%.all.final.vcf: %.fixed.norepeats.snps.sorted.d2i.converted.vcf \
	%.fixed.norepeats.indels.sorted.converted.vcf
	cat VCF.header > $@
	cat $^ >> $@

final: 6d_nescent_2_0.snps.final.vcf 6d_nescent_2_0.indels.final.vcf \
	6d_nescent_2_0.all.final.vcf

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Melt SNPs for database and fix variants info for database  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Sample duplicate variants. This is because we parallelized CRISP, and somehow this results in duplicate variants (because reads overlapping variants can be split?) Only about 120 varaints are affected.
%.all.final.dedup.tab: %.all.final.vcf
	./deduplicate.R $< $@

# Melt VCF into row per sample
%.all.final.samples.tab: %.all.final.dedup.tab
	awk -F"\t" -f melt_samples.awk < $< > $@

# Parse info column
%.all.final.info.tab: %.all.final.dedup.tab
	./variants.R $< $@

.SECONDARY: 6d_nescent_2_0.all.final.info.tab

# Melt VCF into row per allele
%.all.final.variants.tab: %.all.final.info.tab
	awk -F"\t" -f melt_variants.awk < $< > $@
	
melt: 6d_nescent_2_0.all.final.variants.tab \
	6d_nescent_2_0.all.final.samples.tab
