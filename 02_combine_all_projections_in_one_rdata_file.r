# Craig Phillips, Feb 2018. Reads all NZ projections from CSV files, compiles & saves as RData.

rm(list = ls())

getwd()
library(plyr)
library(dplyr)
#--------------------------------------------------------------
# Constants
#--------------------------------------------------------------

proj_read_dir <- 'nz_proj_csv'
rdata_out_dir <- 'rdata_out_files'
rdata_out_fn <- paste0('02_out_nz_proj_cmis_',Sys.Date(),'.RData')

if (!rdata_out_dir %in% list.dirs(recursive = F)) dir.create(rdata_out_dir)

# Add a label stating the area covered by the HOME CMI map
proj_label <- 'all_nz'

#--------------------------------------------------------------
# Function to help extract species name & subsample number from the CSV file name. Returns indices of '_' in the filename so the filename can be trimmed to the required characters.
#--------------------------------------------------------------
fGetIndicesOfCharInString <- function(a_string, the_character) {
	unlist(lapply(strsplit(a_string, ''), function(x) which(x == the_character)))
}

#--------------------------------------------------------------
# Function to read each CSV & add the species name and loop/random subsample number. This function is crude & will cause problems if the HOME projection CSV file name format is altered so that the relative positions of the species name & loop number change.
#--------------------------------------------------------------
fReadAndCsvAndAddVars <- function(csv_fn) {
	indices <- fGetIndicesOfCharInString(csv_fn, '_')
	sp <- substring(csv_fn, 1, indices[2] - 1)
	#loop_num <- substring(csv_fn, indices[5] + 1, indices[5] + 1)
	#sp <- sub('_', ' ', sp)
	csv_fn_split <- unlist(strsplit(csv_fn, ''))
	pos_of_last_underscore <- max(grep('_', csv_fn_split))
	pos_of_last_character <- length(csv_fn_split)
	loop_num <- substr(csv_fn, pos_of_last_underscore + 1, pos_of_last_character-4)
	proj_csv <- read.csv(paste(proj_read_dir, csv_fn, sep = '/'), as.is = T)
	proj_csv$gen_sp <- sp
	proj_csv$loop_num <- loop_num
	return(proj_csv)
}

#--------------------------------------------------------------
# Get vector of CSV file names to process
#--------------------------------------------------------------
csvs_to_combine <- list.files(proj_read_dir, pattern = '.csv')

#--------------------------------------------------------------
# Read each CSV, add species name & loop number, then combine into one dataframe (ldply is from dplyr).
#--------------------------------------------------------------
proj_comp <- ldply(csvs_to_combine, function(x) fReadAndCsvAndAddVars(x), .id = NULL)

# Say what the projection is of
proj_comp$projection <- proj_label

# Save to RData
save(proj_comp, file = paste(rdata_out_dir, rdata_out_fn, sep = '/'))
message(paste('Data saved to', paste(rdata_out_dir, rdata_out_fn, sep = '/')))
