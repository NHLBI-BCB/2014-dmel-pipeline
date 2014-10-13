#!/usr/bin/env Rscript
library(methods)
library(dplyr)
library(data.table)

arguments <- commandArgs(trailingOnly = TRUE)
	
vars_vcf <- fread(
  arguments[1], select = 1:8,
	na.strings = ".",
  colClasses = rep("character", 39))

vars_vcf <- tbl_dt(vars_vcf)

# Parse info column
# This is slow...
vars_vcf[, D2I  := gsub(".*?D2I=(.*?)(;.*|$)", "\\1", INFO)]
vars_vcf[, AF   := gsub(".*?AF=(.*?)(;.*|$)", "\\1", INFO)]
vars_vcf[, NP   := gsub(".*?NP=(.*?)(;.*|$)", "\\1", INFO)]
vars_vcf[, DP   := gsub(".*?DP=(.*?)(;.*|$)", "\\1", INFO)]
vars_vcf[, VT   := gsub(".*?VT=(.*?)(;.*|$)", "\\1", INFO)]
vars_vcf[, CT   := gsub(".*?CT=(.*?)(;.*|$)", "\\1", INFO)]
vars_vcf[, QVpf := gsub(".*?QVpf=(.*?)(;.*|$)", "\\1", INFO)]
vars_vcf[, QVpr := gsub(".*?QVpr=(.*?)(;.*|$)", "\\1", INFO)]
vars_vcf[, VP   := gsub(".*?VP=(.*?)(;.*|$)", "\\1", INFO)]
vars_vcf[, MQ   := gsub(".*?MQ=(.*?)(;.*|$)", "\\1", INFO)]

# Delete info column
vars_vcf[ ,INFO := NULL]

# Fill in NAs
for (i in seq_len(ncol(vars_vcf))){
  set(vars_vcf, which(vars_vcf[[i]] == "."), i, NA_character_)
}

# write out to tab
write.table(vars_vcf, file = arguments[2],
  quote = FALSE, sep = "\t", row.names = FALSE)
