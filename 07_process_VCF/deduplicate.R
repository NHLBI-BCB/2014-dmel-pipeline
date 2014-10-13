#!/usr/bin/env Rscript
# This R script reads in the vcf, replaces the big header with a simple column names header, then samples 1 of each duplicate variant. Duplicated variants occur because when we split the bam files by regions for variant calling some reads overlapped the same variant and so were called twice. I guess...
library(methods)
library(dplyr)
library(data.table)

arguments <- commandArgs(trailingOnly = TRUE)

vars_vcf <- fread(
  arguments[1],
	na.strings = ".",
  colClasses = rep("character", 39))

vars_vcf <- tbl_dt(vars_vcf)

vcf_header <- readLines(
  arguments[1], n = 30) %>% 
  grep("^#C.*", ., value=TRUE) %>% strsplit(., "\t") %>% unlist(.)

# Variable Names
setnames(vars_vcf, names(vars_vcf), vcf_header)

setnames(vars_vcf, "#CHROM", "CHROM")

vars_vcf <- vars_vcf %>% group_by(CHROM, POS, ALT) %>% sample_n(1)

# write out to tab
write.table(vars_vcf, file = arguments[2],
  quote = FALSE, sep = "\t", row.names = FALSE)
