#--------------------------------------------------------------
# Craig Phillips, Dec 2016, revised for Mariona 15-Jun-2018
#--------------------------------------------------------------

rm(list = ls())


library(plyr)
library(dplyr)

setwd('C:/00_2018/00_Validations/climex-for-linux') 


#--------------------------------------------------------------
# Constants
#--------------------------------------------------------------

# Number of loops/random subsamples to process
iterations <- 3

# Number of presence points that will be randomly subsampled
sub_sample_size <- 20

# The script changes the working directory to where the C++ program is & needs to get back to this one afterwards, so store the current dir here. Sometimes the format of r_work_dir is wrong (an AGR network issue), so the 'if' statement tries to fix it
r_work_dir <- getwd(); r_work_dir
 
#if (grep('\\\\', r_work_dir)) r_work_dir <- gsub('\\\\', '/', r_work_dir)

# Dir where the (tidied) HOME projections will be written as CSVs. 
csv_out_dir <- 'nz_proj_csv'

if (!dir.exists('nz_proj_csv')) dir.create('nz_proj_csv')

# File of non-NZ presence points (pps). This file contains each M. aquatica presence point & the ID of the non-NZ climate cell that it coincides with. It is used for filtering the non-NZ (AWAY) climate data to those that correspond with each random subset of M. aquatica data. This RData file was generated by another script which, to help keep things simple, is not yet in this directory.
pp_fn <- 'mentha_aquatica_non_nz_cmis.RData' 

# Dir of CLIMEX-MCR C++ program & associated climate data. CLIMEX-MCR won't run on the network, so you'll need to copy it to your C drive, then change 'climex_mcr_dir' to match
# climex_mcr_dir <- 'C:/CP progs/mcr_cpp_for_mariona' 
 climex_mcr_dir <- 'C:/00_2018/00_Validations/climex_test/mcr_cpp_for_mariona'

# Dir of AWAY climate rdata. These will be filtered to each species' presence points & written as CSV to be used by CLIMEX-MCR C++ as the AWAY climate data. They're faster to load as RData than as CSV (there are >3 million weekly climate records).
climate_data_fn <- 'WorldWithoutNzDataByWeek24Apr2018.RData' # the loaded object is called 'A'

# Name of bat file that will launch CLIMEX-MCR C++
nz_proj_bat_fname <- 'RunAllNzProjection.bat'

# Name of a bat file that joins 7 output files from CLIMEX-MCR C++
join_out_files_bat_fname <- "JoinOutFiles.bat"

# Names of the 7 output files from C++. 'out_files' is used to delete the files after they've been processed use to reduce potential for mix-ups when CLIMEX-MCR C++ is run next time.
out_files <- paste0('out', 1: 7, '.csv'); out_files

# Number of HOMME (NZ) climate locations. Used to calculate SNOOZE time (explained later) & the numbers of climate records assigned to each PC core by CLIMEX-MCR. The number of records per core is defined in 'RunAllNzProjection.bat'
home_locs <- 11471 

#--------------------------------------------------------------
# Load world climate data, hazards' overseas CMIs, & hazard list
#--------------------------------------------------------------
# Load world climate data, a subset of which will be compared with NZ.
if (!exists('A')) load(climate_data_fn) # world climate data "A", big file so takes a while to load

# Use Mentha aquatica's overseas CMIs, already obtained using code not shown here, to obtain the ID of the climate cell that each presence point occurs in. These climate cell IDs will be used to filter the world climate data to the locations of the presence points. (The presence points have already been cleaned.)
load(pp_fn) # m_aquatica_non_nz_cmis

pp_cmis <- m_aquatica_non_nz_cmis # make a shorter name
rm(m_aquatica_non_nz_cmis) # remove the object with the long name

dim(pp_cmis) # 189835 x 10
#names(pp_cmis)

# Adjust some variable names
if ('Loc1Lon' %in% names(pp_cmis)) {
	names(pp_cmis) <- sub('Loc1', '', names(pp_cmis))
}

# Exclude any NZ records & any records with cliKey == NA
b4 <- nrow(pp_cmis)
pp_cmis %>%
	filter(!(Lat > -47.5 & Lat < -34.5 & Lon > 166 & Lon < 180)) %>%
	filter(!is.na(cliKey)) -> pp_cmis
if (b4 - nrow(pp_cmis) > 0) {
	message(paste('NZ records removed =', b4 - nrow(pp_cmis))) 
	message(paste('Remaining records =', nrow(pp_cmis))) 
}

#--------------------------------------------------------------
# Loop through random subsamples of Mentha aquatica presence points
#--------------------------------------------------------------
# i<-948
# sub_sample_size <- 948

for (i in 1: iterations) {
	
	# Take a random subsample of the data
	if (nrow(pp_cmis) > sub_sample_size) {
	# We may want to set.seed to get reproducible results
		set.seed(i * 2) #**CP I was reading about how set.seed works & now think we should set.seed just once, before the start of the loop, without multiplying it by i in each loop.
		pp_sub <- sample_n(pp_cmis, sub_sample_size) # sample_n is from dplyr
	} else { 
		stop('Subsample size is too big for the available data')
	}

	# Put a '_' between sp & gen for use in output CSV file names
	sp_name <- gsub(" ", "_", unique(pp_sub$gen_sp)); sp_name

	#--------------------------------------------------------------
	# Get climate data to create NZ projection & write to dir that contains C++
	# version of CLIMEX
	#--------------------------------------------------------------
	cli_cells <- unique(pp_sub$cliKey)

	# There may be fewer cli_cells than records because we often have multiple presence points per climate cell
	nrow(pp_sub); length(cli_cells)

	# Filter world climate data to locations of pp_sub
	pp_cli_data <- filter(A, Key %in% cli_cells)

	# Write climate data for this subset of presence points to ClimexMCR C++ dir
	pp_cli_dat_fname <- paste0(sp_name, "_PpCliData.csv")

	write.csv(pp_cli_data, file = paste(climex_mcr_dir, pp_cli_dat_fname, sep = '/'),
						row.names = F)

	message(paste('Away climate data written to', 
								 paste(climex_mcr_dir, pp_cli_dat_fname, sep = '/')))

	# Update the C++ bat file that joins the 'out.csv' files by adding a number to the output file name which equals the iteration  number of this loop. The iteration number will be used to distinguish between HOME CMI outputs derived from different subsets of AWAY data.
	old_bat <- readLines(paste(climex_mcr_dir, join_out_files_bat_fname, sep = '/'))
	old_bat
	new_bat <- gsub("([0-9]+).*$", paste0(i, '.csv'), old_bat)
	new_bat

	# Write the new bat file to disc
	cat(new_bat, file = paste(climex_mcr_dir, join_out_files_bat_fname, sep = '/'), 
							 sep = "\n")

	#--------------------------------------------------------------
	# Change wd to where C++ is
	#--------------------------------------------------------------
	setwd(climex_mcr_dir) # dir of C++ version of CLIMEX

	#--------------------------------------------------------------
	# Run both the bat files. The 1st bat file needs to finish before the 2nd starts, & the 2nd bat file needs to finish before the R code resumes. So put R to sleep while they run. R will wait for the 1st bat file to run for the number of seconds defined by 'snooze'. The 2nd bat file only needs 1-2 seconds to run.
	#--------------------------------------------------------------

	snooze <- max(40, home_locs * 2 * nrow(pp_cli_data) * 10^-6)
	snooze <- snooze * 2

	shell(nz_proj_bat_fname)
	Sys.sleep(snooze)
	# C++ will take a minimum of 40 s to complete the climate match.

	shell(join_out_files_bat_fname)
	Sys.sleep(2)

	#--------------------------------------------------------------
	# Read, tidy & save HOME projection CSV to new dir
	#--------------------------------------------------------------
	home_proj_fn <- paste0(sp_name, '_all_nz_proj_', i, '.csv')

	hm_proj <- read.csv(home_proj_fn, as.is = TRUE)

	# Delete superfluous headers produced when the bat file joined the 'out.csv' files
	hm_proj <- hm_proj[!hm_proj$Loc1Key == "Loc1Key", ]

	# All the vars in hm_proj should have class character even though they're numeric, so convert to numeric
	hm_proj <- mutate_all(hm_proj, funs(as.numeric))

	# Add a var called cmiRnd to the projection
	hm_proj$cmiRnd <- round(hm_proj$BestCMI, 1)

	nrow(hm_proj) # 11471 for all of NZ

	#--------------------------------------------------------------
	# Delete old CSVs from C++ dir
	#--------------------------------------------------------------
	# delete all  'out.csv' files
	sapply(out_files, function(x) if (file.exists(x)) file.remove(x))

	if (file.exists(home_proj_fn)) file.remove(home_proj_fn)
	if (file.exists(pp_cli_dat_fname)) file.remove(pp_cli_dat_fname)

	#--------------------------------------------------------------
	# Write updated projection to CSV is a subdir of the original R working directory, rather than in the dir (on C drive) where the C++ program is
	#--------------------------------------------------------------
  setwd(r_work_dir) 

	write.csv(hm_proj, 
						paste(csv_out_dir, home_proj_fn, sep = '/'), 
						row.names = FALSE)

	message(paste0(i, ' of ', iterations, ': Result written to ', 
		paste(csv_out_dir, home_proj_fn, sep = '/'), '\n'))

} # End for (i in 1: iterations)
