# Primer ID Template Consensus Sequence (TCS) Pipeline

## RUBY Script to creat Primer ID tempalate consensus from raw MiSeq fastq files

## Scripts List

    TCS.rb          -The general script to construct TCS
    
    Dr.rb           -The script to construct TCS for the MPID-HIVDR MiSeq sequencing. Post-TCS QC will check if the TCSs are in the correct sequencing regions
    
    log_multi.rb    -Format and sort TCSs and libraries after TCS.rb or DR.rb
    
    SDRM.rb         -Surveillance Drug Resistance Mutation (SDRM) analysis using TCSs from the Dr.rb pipeline, also generate N-J trees and calculate Pi and first quintile of pairwise comparison.
    
    sequence.rb     -functions and constants
    
## Updates

### TCS script Version 1.37-24MAY2018 and DR Version 1.06-24MAY2018
	
	1. Input files can be either .fastq or .fastq.gz, will unzip if it is .gz file
	2. Minor improvement of efficiency


### TCS script Version 1.36-01MAY2018 and DR Version 1.05-01MAY2018

	1. Remove the temp_dir if fail to create TCS

### DR script Version 1.04-18APR2018

	1. Fix a bug of method #sequence_locator. Refine the alignment if the ref sequence restarts and/or ends with "-"


### DR script Version 1.03-07DEC2017

	1. Fix a bug of method #sequence_locator

### DR script Version 1.02-21NOV2017

	1. Update new V3 DR primer. 

### Version 1.34-14NOV2017

	1. If the forward primer does not contain "N"s, the whole sequence will be used as the biological forward primer. 

### Version 1.33-19FEB2016

	1. consensus cut-off model based on 3 levels of error rate (0.02, 0.01, 0.005). By default 0.02. 


### Version 1.32-24JAN2016

	1. Adapted to TCS website
	2. Compress output directory in .tar.gz file


### Version 1.31-14NOV2016
Patch Notes

	1. ADDING PRIMER ID FILTER AFTER CONCENSUS CREATION
        	1. Compare PID with sequences which have identical sequences.
        	2. PIDs differ by 1 base will be recognized. If PID1 is x time greater than PID2, PID2 will be disgarded
        	3. PID factor x is 10 by default.
       		4. PID filter only apply when the number of potential consensus sequences is less than 0.3% of the maximum capacity of PID. 

### Version 1.30-23SEP2016
Patch Notes:

    1.Add Primer ID filter after consensus creation. Compare PID with sequences which have identical sequences. PIDs differ by 1 base will be recognized. If PID1 is x time greater than PID2, PID2 will be disgarded. PID factor x is 10 by default. 

### Version 1.21-18JUL2016
Patch Notes:

    1.Allow ambituities of bases in the gene specific sequences. 

### Version 1.20-05JUN2016
Patch Notes:

    1.Now allow multiplexed Primer ID sequencing system. Input primers in pairs for all sets.
    
    2.Add option to ignore the 1st nucleotide of the Primer ID. 

Create Primer ID template consensus sequences from raw MiSeq FASTq file

Input = directory of raw sequences of two ends (R1 and R2 fasta files)

Require parameters:

    list of Primer Sequence of cDNA primer and 1st round PCR forward Primer, including a tag for the pair name
    
    ignore the first nucleotide of Primer ID: Yes/No (default: Yes)



### Version 1.11-24FEB2016
Patch Notes:

    1. consensus cut-off calculation using average number of top 5 abundant Primer ID
    2. Add 'resampling indicator' = consensus without ambuiguities / all consensus including ambuiguities.

Create Primer ID template consensus sequences from raw MiSeq FASTq file

Input = directory of raw sequences of two ends (R1 and R2 fasta files)

Require parameters:

    Length of Primer ID
  
    Primer Sequence of cDNA primer and 1st round PCR forward Primer


### Version 1.10-09302015
