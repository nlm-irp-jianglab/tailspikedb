infile=$1
awk -F"\t" '{split($4,a,";");print $1"\t"$2"\t"$3"\t"a[1]"\t"$5"\t"$6}' $infile | sort -V -k1,1 > ${infile}.1
mv ${infile}.1 ${infile}
