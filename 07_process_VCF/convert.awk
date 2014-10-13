{
  # Reset variables
  nAlleles=0
  np=0
  totalAD=0
  totalDP=0
  for(i in alleleAD){
    delete alleleAD[i]
  }

  # Strip header if exists unchanged
  if(substr($1, 1, 1)=="#") {
  next
  } else {
    # Maintains first 7 columns (pos, chr, etc.)
    # Strip arm_ from chromosome column
    sub(/arm_/, "", $1)
    for(i=1; i<=7; i++) {
      printf $i"\t"
    }
    # get total allele frequency
    for(i=10; i<=NF; i++) {
      split($i, alleleCounts, ":")
      nAlleles = split(alleleCounts[3], forwardCounts, ",")
      split(alleleCounts[4], reverseCounts, ",")
  
      rd[i-9] = 0
      for(n=1; n<=nAlleles; n++) {
        alleleCounts[n] = forwardCounts[n] + reverseCounts[n]
        rd[i-9] = rd[i-9] + alleleCounts[n]
        totalDP += forwardCounts[n] + reverseCounts[n]
      }
      for(n=2; n<=nAlleles; n++) {
        if(n==2) alleleOutput[i-9] = alleleCounts[n]
        if(n>2 && n<=nAlleles) alleleOutput[i-9] = sprintf("%s,%i", alleleOutput[i-9], alleleCounts[n])
        totalAD += forwardCounts[n] + reverseCounts[n]
        alleleAD[n-1] += forwardCounts[n] + reverseCounts[n]
      }
    }
  
    # print info column
    printf "AF="totalAD/totalDP
    if(nAlleles>2){
      for(n=1; n<nAlleles; n++) {
        printf ","alleleAD[n]/totalDP
      } 
    }
    printf ";"$8"\t"
  
    # print format column
    printf "AD:DP\t"
  
    #print population columns
    for(i=10; i<=NF; i++) {
      if(rd[i-9] > 0) printf alleleOutput[i-9]":"rd[i-9]
      if(rd[i-9] == 0) printf "0:0"
      if(i<NF) printf "\t"
      if(i==NF) printf "\n"
    }
  }
}