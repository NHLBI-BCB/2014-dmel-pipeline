# This awk script melts a vcf file into one row for each position and allele. Drops sample info.
{
  # Print new header
  if(NR == 1) { 
  printf "chrom\tpos\tallele\tnalleles\tref\talt\tqual\td2i\taf\tnp\tdp\tvt\tct\tQVpf\tQVpr\tvp\tmq\n"
  } else{
    nAlleles = split($5, ALT, ",")
    if(nAlleles > 1) {
      split($9, AF, ",")
      split($13, CT, ",")
      split($14, QVpf, ",")
      split($15, QVpr, ",")
      split($16, VP, ",")
      for(n=1; n<=nAlleles; n++) {
        printf $1"\t"$2"\t"n"\t"nAlleles"\t"$4"\t"ALT[n]"\t"$6"\t"$8"\t"AF[n+1]"\t"$10"\t"$11"\t"$12"\t"CT[n]"\t"QVpf[n]"\t"QVpr[n]"\t"VP[n]"\t"$17"\n"
      }
    } else{
      printf $1"\t"$2"\t"1"\t"1"\t"$4"\t"$5"\t"$6"\t"$8"\t"$9"\t"$10"\t"$11"\t"$12"\t"$13"\t"$14"\t"$15"\t"$16"\t"$17"\n"
    }
  }
}
