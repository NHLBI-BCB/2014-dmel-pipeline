#!/usr/bin/env Rscript
# printArgs.r -- does just what it says

arguments <- commandArgs(trailingOnly=TRUE)
for (i in 1:length(arguments)) {
  print(paste("arg",as.character(i),"=",arguments[i]))
}