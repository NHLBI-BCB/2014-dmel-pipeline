# D. melanogaster variant calling pipeline

This pipeline maps, decontaminates and calls variants for pooled drosophila melanogaster sequence data.

##00_reference
Download D. melanogaster and D. simulans reference genomes

##01_sample_data
Create symlinks (to save diskspace) to all raw sequence data.

##02_mapping
Map raw reads to reference genome using bwa-mem, deduplicate, re-align using GATK. (plus fix phred scores for some read libraries).

##03_divergence
Identify SNPs that are 100% divergent between Drosophila melanogaster and Drosophila simulans. These divergent SNPs can be used to test for D. simulans contamination in the D. melanogaster pooled sequences.

##04_detect_contamination
Test for D. simulans contamination in the D. melanogaster pooled samples.

##05_decontaminate
Decontaminate the contaminated samples by competitive mapping to D. melanogaster and D. simulans genomes.

##06_call_variants
Use CRISP to call variants.

##07_process_VCF
Fix some errors in CRISP output, convert allele frequenceis to ad:dp format, deal with multiple allele SNP per row (unwind so that 1 allele per row), calculate distance to nearest indel, format VCF for import into a SQL type database.