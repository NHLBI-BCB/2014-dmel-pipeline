{
  # Copy file header unchanged
  if(substr($1, 1, 1) == "#") {
    print $0
  } else {
    # Check if REF and ALT columns are concatenated with a space (should be a tab)
    # Then fix with a tab
    sub(/[ ]/, "\t", $4)
    # Print all fields but 6, which seems to be extra...
    for(i=1; i<6; i++) {
      printf $i"\t"
    }
    for(i=7; i<NF; i++) {
      printf $i"\t"
    }
    printf $NF"\n"
  }
}