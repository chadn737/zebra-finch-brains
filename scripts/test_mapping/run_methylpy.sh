#PBS -S /bin/bash
#PBS -q batch
#PBS -N PE_test
#PBS -l nodes=1:ppn=12:HIGHMEM
#PBS -l walltime=480:00:00
#PBS -l mem=100gb

cd $PBS_O_WORKDIR
module load python/2.7.8
echo "Starting"
mkdir allc reports
sample=$(pwd | sed s/.*data\\/// | sed s/\\/methylCseq//)

#Uncompress fastq files
cd ../fastq/methylCseq
echo "Uncompressing fastq files"
for i in *gz
do
  gunzip "$i"
done

#Run methylpy
cd ../../methylCseq
echo "run methylpy"
module load python/2.7.8
python ../../../scripts/test_mapping/run_methylpy.py "$sample" "../fastq/methylCseq/*R1_001.fastq" \
"../fastq/methylCseq/*R2_001.fastq" "../../ref/methylCseq/Tguttata_v3.2.4" "10" "9" "ChrL" \
> reports/"$sample"_output.txt

#Format allc files
echo "Formatting allc files"
mv allc_* allc/
cd allc
mkdir tmp
head -1 allc_"$sample"_ChrL.tsv > tmp/header
for i in allc_"$sample"_*
do
  sed '1d' "$i" > tmp/"$i"
done

tar -cjvf "$sample"_allc.tar.bz2 allc_"$sample"_*
rm allc_*
cd tmp
rm allc_"$sample"_ChrL.tsv allc_"$sample"_MT.tsv
cat header allc_* > ../"$sample"_allc_total.tsv
cd ../
rm -R tmp
tar -cjvf "$sample"_allc_total.tar.bz2 "$sample"_allc_total.tsv
cd ../

#Cleanup directory
echo "Cleaning up intermediate files"
rm *mpileup* *.bam *.bam.bai

#Compress fastq files
cd ../fastq/methylCseq
echo "Compressing fastq files"
for i in *fastq
do
  gzip "$i"
done
cd ../../methylCseq

echo "done"
