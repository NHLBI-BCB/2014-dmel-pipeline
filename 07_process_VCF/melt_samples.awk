# This awk script melts a positions file into one row for each position & allele
{
  if(NR == 1) { 
  # print column names and save header
  split($0, HEADER, "\t")
  # print new column names
  printf "chrom\tpos\tref\talt\tsample_name\tad\tdp\tallele\tnalleles\n"
  } else{
    nAlleles = split($5, ALT, ",")
    REF = $4
    for(i=10; i<=NF; i++) {
      split($i, ADDP, ":")
      split(ADDP[1], AD, ",")
      for(n=1; n<=nAlleles; n++){
        printf $1"\t"$2"\t"REF"\t"ALT[n]"\t"HEADER[i]"\t"AD[n]"\t"ADDP[2]"\t"n"\t"nAlleles"\n"
      }
    }
  }
}
