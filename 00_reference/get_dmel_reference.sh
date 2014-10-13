# Dmel release5 reference genome
curl -O -sS ftp://ftp.fruitfly.org/pub/download/compressed/dmel_release5.tgz
tar -xvf dmel_release5.tgz
cd Dmel_Release5/ && \
cat na_2LHet.dmel.RELEASE5 na_2RHet.dmel.RELEASE5 na_3LHet.dmel.RELEASE5 \
	na_3RHet.dmel.RELEASE5 na_arm2L.dmel.RELEASE5 na_arm2R.dmel.RELEASE5 \
	na_arm3L.dmel.RELEASE5 na_arm3R.dmel.RELEASE5 na_arm4.dmel.RELEASE5 \
	na_armU.dmel.RELEASE5 na_armUextra.dmel.RELEASE5 na_armX.dmel.RELEASE5 \
	na_XHet.dmel.RELEASE5 na_YHet.dmel.RELEASE5 > ../all_Dmel_Release5.fasta
cd ..
rm dmel_release5.tgz
rm -rf Dmel_Release5/
gzip all_Dmel_Release5.fasta
bwa index all_Dmel_Release5.fasta.gz
