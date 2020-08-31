#!/bin/bash --login
#SBATCH --time=3:59:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --mem=20GB
#SBATCH --job-name STAR
#SBATCH --output=%x-%j.SLURMout

cd $PBS_O_WORKDIR
export PATH="$HOME/miniconda3/envs/zebra-finch-brains/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/miniconda3/envs/zebra-finch-brains/lib:$LD_LIBRARY_PATH"

#set Variables
samples="MCH1 MCH2 MCH3 MTH1 MTH2 MTH3 MCNT1 MCNT2 MCNT3 MTNT1 MTNT2 MTNT3"
index="../../ref/star"
output1="rnaseq1"
output2="rnaseq2"
threads=20
fastq="../fastq/rnaseq/all.fastq.gz"

#Star 1st pass
echo "Running star 1st pass"
for i in $samples
do
	echo "Running sample: $i"
	mkdir $i/$output1 $i/$output2
	cd $i/$output1
	STAR \
		--runThreadN $threads \
		--runMode alignReads \
		--genomeDir $index \
		--readFilesIn $fastq \
		--readFilesCommand zcat \
		--outSAMtype BAM SortedByCoordinate \
		--outSAMstrandField intronMotif \
		--outFilterType BySJout \
		--outFilterMultimapNmax 20 \
		--alignSJoverhangMin 8 \
		--alignSJDBoverhangMin 1 \
		--alignIntronMin 20 \
		--alignIntronMax 1000000 \
		--outFilterMismatchNmax 999 \
		--outFilterMismatchNoverReadLmax 0.04
	junctions="../../"$i"/"$output1"/SJ.out.tab $junctions"
	cd ../../
done
echo $junctions

#Star 2nd pass
echo "Running star 2nd pass"
for i in $samples
do
	echo "Running sample: $i"
	cd $i/$output2
	STAR \
		--runThreadN $threads \
		--runMode alignReads \
		--genomeDir $index \
		--readFilesIn "$fastq" \
		--sjdbFileChrStartEnd $junctions \
		--readFilesCommand zcat \
		--outSAMtype BAM SortedByCoordinate \
		--outSAMstrandField intronMotif \
		--outFilterType BySJout \
		--outFilterMultimapNmax 20 \
		--alignSJoverhangMin 8 \
		--alignSJDBoverhangMin 1 \
		--alignIntronMin 20 \
		--alignIntronMax 1000000 \
		--outFilterMismatchNmax 999 \
		--outFilterMismatchNoverReadLmax 0.04 \
		--quantMode GeneCounts
	cut -f1,4 ReadsPerGene.out.tab | sed '1,4d' > "$i"_counts.tsv 
	cd ../../
done

echo "Done"

