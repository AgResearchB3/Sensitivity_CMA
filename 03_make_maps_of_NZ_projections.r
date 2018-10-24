## Craig Phillips, Feb 2018
library(plyr)
library(dplyr)

rm(list = ls())

getwd()

#--------------------------------------------------------------
# Constants
#--------------------------------------------------------------
proj_read_dir <- 'rdata_out_files'
map_out_dir <- 'nz_proj_maps'

if (!map_out_dir %in% list.dirs(recursive = F)) {
	dir.create(map_out_dir) }

#---------------------------------------------------------
# Function that plots NZ CMI map
#---------------------------------------------------------
source('fGgplotNzClimexMcrProjection.r')

#---------------------------------------------------------
# Read RData of projections to plot
#---------------------------------------------------------
dir(proj_read_dir, pattern = '.RData')

load(paste(proj_read_dir, '02_out_nz_proj_cmis_15Jun2018.RData', sep = '/')) # proj_comp

#--------------------------------------------------------------------------------
# Loop through each projection. In each loop, 'fGgplotNzClimexMcrProjection' will generate a warning, which can be ignored. (I have code to suppress the warning, but omitted it to simplify this script.)
#--------------------------------------------------------------------------------
for (i in 1: length(unique(proj_comp$loop_num))) {  

	plot_dat <- filter(proj_comp, loop_num == i)
  sp_and_loop_num <- paste0(unique(plot_dat$gen_sp), '_', unique(plot_dat$loop_num))
	sp_and_loop_num  <- sub(' ', '_', sp_and_loop_num )
	map_file_name <- paste0(map_out_dir, '/', sp_and_loop_num, '.png')

	map <- fGgplotNzClimexMcrProjection(plot_dat, sp_and_loop_num)

	png(filename = paste(map_file_name), width = 960, height = 960, res = 100)
		print(map)
	dev.off()

	# PDFs are better quality for zooming into
	#	pdf(file = paste(map_file_name), paper = 'a4r', width = 0, height = 0)
	#		print(map)
	#	dev.off()
	
	message(paste0(i, ' of ', length(unique(proj_comp$loop_num)),
													': Saved ', map_file_name))
	flush.console()
}

