# Primer ID Consensus
RUBY Script to creat Primer ID tempalate consensus from raw MiSeq fastq files

#Version 1.20-05JUN2016
Patch Notes:

    1.Now allow multiplexed Primer ID sequencing system. Input primers in pairs for all sets.
    
    2.Add option to ignore the 1st nucleotide of the Primer ID. 

Create Primer ID template consensus sequences from raw MiSeq FASTq file

Input = directory of raw sequences of two ends (R1 and R2 fasta files)

Require parameters:

    list of Primer Sequence of cDNA primer and 1st round PCR forward Primer, including a tag for the pair name
    
    ignore the first nucleotide of Primer ID: Yes/No (default: Yes)



#Version 1.11-24FEB2016
Patch Notes:

    1. consensus cut-off calculation using average number of top 5 abundant Primer ID
    2. Add 'resampling indicator' = consensus without ambuiguities / all consensus including ambuiguities.

Create Primer ID template consensus sequences from raw MiSeq FASTq file

Input = directory of raw sequences of two ends (R1 and R2 fasta files)

Require parameters:

    Length of Primer ID
  
    Primer Sequence of cDNA primer and 1st round PCR forward Primer


#Version 1.10-09302015
