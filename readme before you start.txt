Craig Phillips, 15-Jun-2018. Notes for Mariona

## Script '01_get_nz_projections.r' ##
A CMI map is created for a HOME region by comparing its climate data to those of some AWAY locations. AWAY locations can comprise a geographical region, or a set of  locations where a species has been recorded (presence points). This example script for investigating sensitivity uses presence points for a plant, Mentha aquatica, because it has around 190,000 GBIF records. The script uses a loop to repeatedly take random subsamples of M. aqauatica presence points & match them with the HOME region, which in this case is NZ. For each data subset, it outputs a CSV file containing the HOME CMIs, which can then be mapped/analysed in subsequent scripts. For now, I've just included a script that makes the maps (see below).

You should be able to submit all of '01_get_nz_projections.r' to R at once. It is set up to run through 3 short loops, each taking around 45 s on my computer.

## Files in the subdirectory 'mcr_cpp_for_mariona':
The CLIMEX-MCR climate matching algorithm is performed by a separate C++ program, which I've copied to the sub-directory 'mcr_cpp_for_mariona'. The C++ program won't run on the network, so you'll need to copy this directory to your C drive, & specify the path to your C drive directory in the CONSTANTS section of '01_get_nz_projections.r'.

Once you've copied the directory 'mcr_cpp_for_mariona' to your C drive, you don't need to do anything to the files that it contains.

'mcr_cpp_for_mariona' also contains 2 CSV files of climate data (HOME & AWAY), which will be matched by the C++ program. The HOME climate data remain constant in every loop in '01_get_nz_projections.r', but the AWAY climate data -- ie, random subsamples of M. aquatica presence points -- change with each loop. In each loop, script '01_get_nz_projections.r' filters the AWAY climate data to those of M. aquatica's presence points and writes them as a CSV file to 'mcr_cpp_for_mariona'. So every loop will probably produce a different CMI map because each subsample of M. aquatica presence points should be different.

The C++ program runs 7 cores in parallel. While it is running, 7 windows command screens will open & show progress. The C++ program outputs the HOME CMIs as 7 separate CSV files (one for each core used during parallel processing). These are joined and prepared for mapping/analysis as described below.

The C++ directory contains two '.bat' files. One ('RunAllNzProjection.bat') gives the parameters used by the C++ code, and the other ('JoinOutFiles.bat') joins the 7 output CSV files into one CSV. The bat files are  'automatically' updated by the script '01_get_nz_projections.r'. The C++ program ('.exe') is also launched by script '01_get_nz_projections.r'.

The bat file that joins the 7 output CSV files is also launched by script '01_get_nz_projections.r'. However, this bat file doesn't do a perfect job of formatting the data, so towards the end of each loop, '01_get_nz_projections.r' reads the CSV file produced by the bat file, tidys it, then writes it back to disc.

The time taken by the C++ program to run varies with the number of locations in the HOME & AWAY data. For example, a match between the whole world (AWAY) & NZ (HOME) can take several hours. A typical smaller job takes <10 minutes. In '01_get_nz_projections.r', I've specified a small subsample of M. aquatica points & just 3 iterations, so each loop should only take <1 minute to run. For proper sensitivity work, you will probably want to increase/vary the number of points that are subsampled.

## Script '02_combine_all_projections_in_one_rdata_file.r' ##
A separate CSV of HOME CMI data is produced from each subsample of M. aquatica presence points. This script combines all the CSVs and saves them as an RData file. A variable called loop-num identifies which subset of M. aquatica presence points the CMI data are from. Having all the CMI data in one RData file makes it faster and easier to create maps and analyse the data. You should be able to submit all of this script to R at once. 

## Script ## 03_make_maps_of_NZ_projections.r' ##
This script makes the NZ CMI maps & saves them as PNG. You should be able to submit all of this script to R at once. 



