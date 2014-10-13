# Create divergence file
This pipeline creates a divergence file for melanogaster and simulans. The divergence file contains SNPs that are fixed for either mel or sim. This divergence file can then be used to detect contamination of sim in mel sequence reads. See makefile for details.

Some of the raw data will be downloaded by the makefile, some will need to be manually added to this directory (see makefile for details).

This pipeline needs curl, java, python, the 'simulans_contamination' scripts from Mark Kupin, bwa, samtools, SRA toolkit and popoolation scripts.

    sudo yum install curl
    sudo yum install java
    sudo yum install python
    sudo yum install python-devel
    # Depending on python install may need some packages
    sudo yum install python-pip
    pip install rpy2
    #Install:
    #bwa from here: http://bio-bwa.sourceforge.net
    #samtools: http://samtools.sourceforge.net
    #sra toolkit: http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?view=software