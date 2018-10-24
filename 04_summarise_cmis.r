## Craig Phillips, 8-Aug-2018. Need to vary plot parameters in this script to suit different sets of species.

library(plyr)
library(dplyr)
library(forcats) # for fct_rev
library(ggplot2)

rm(list = ls())
getwd()
setwd('C:/00_2018/00_Validations/climex-for-linux')

#---------------------------------------------------------
# Constants
#---------------------------------------------------------

base_dir <- '.'

rdata_read_dir <- paste(base_dir, 'rdata_out_files', sep = '/')
details = file.info(list.files(rdata_read_dir, pattern="*.RData",full.names = TRUE)) ## extract the metadata of all files in r_data_dir
rdata_read_fn <- row.names(details[rev(order(details$mtime)),])[1] ## select the most recently modified

summ_out_dir <- paste(base_dir, 'nz_proj_summarised', sep = '/')
if (!dir.exists(summ_out_dir)) dir.create(summ_out_dir)

facplot_all_out_fn <- paste0('04_out_cmis_fac_by_subsample_',Sys.Date(),'.png') # facet plot
facplot_finer_out_fn <- paste0('04_out_cmis_fac_by_finer_subsample_',Sys.Date(),'.png')
boxplot_out_fn <- paste0('04_out_cmis_boxplot_by_subsample_',Sys.Date(),'.png') # box plot

#---------------------------------------------------------
# Load CMI data
#---------------------------------------------------------
#load(rdata_read_fn) # proj_comp
load('./rdata_out_files/04_out_nz_proj_cmis_17September2018.RData')
tail(proj_comp)

proj_comp$subsample_sz <- proj_comp$subsample_sz * 100
head(proj_comp)

#--------------------------------------------------------------
# Summarise results for NZ CMI
#--------------------------------------------------------------

summary(proj_comp)

#--------------------------------------------------------------
# Summarise results for NZ CMI maps from each subsample size
#--------------------------------------------------------------
table(proj_comp$cmiRnd)
chk <- filter(proj_comp, cmiRnd < 0 | cmiRnd > 1)
#View(chk)


cmi_min_max_mean_sd_by_subsample <-
	proj_comp %>%
		group_by(subsample_sz) %>%
		summarise(min_cmi = min(BestCMI, na.rm = TRUE),
							max_cmi = max(BestCMI, na.rm = TRUE),
							mean_cmi = round(mean(BestCMI, na.rm = TRUE), 5),
							sd_cmi = round(sd(BestCMI, na.rm = TRUE), 5))

tail(cmi_min_max_mean_sd_by_subsample, n = 20)

save(cmi_min_max_mean_sd_by_subsample, file = paste(summ_out_dir, 'cmi_min_max_mean_sd_by_subsample.RData', sep = '/'))

cmis_per_subsample <-
	as.numeric(proj_comp %>%
		filter(subsample_sz == subsample_sz[1]) %>%
		summarise(cmis = length(cmiRnd)))

count_and_proportion_per_cmi_by_subsample <-
	proj_comp %>%
		group_by(subsample_sz, cmiRnd) %>%
		summarise(cmi_n = length(Loc1Key)) %>%
		mutate(proportion = round(cmi_n/cmis_per_subsample, 4))

head(count_and_proportion_per_cmi_by_subsample, n = 20)

save(count_and_proportion_per_cmi_by_subsample, file = paste(summ_out_dir, 'count_and_proportion_per_cmi_by_subsample.RData', sep = '/'))

#--------------------------------------------------------------
# Facet plot CMI proportions per species.
#--------------------------------------------------------------
length(unique(count_and_proportion_per_cmi_by_subsample$subsample_sz)) # 321
summary(count_and_proportion_per_cmi_by_subsample$subsample_sz) # range 100 to 32100
plot(count_and_proportion_per_cmi_by_subsample$subsample_sz)

# There are 1000 different subsample sizes. For plotting, just take a subsample
result_subset_all<-
	count_and_proportion_per_cmi_by_subsample %>%
	filter(subsample_sz %in% c(100, seq(2500, 30000, 2500)))

result_subset_finer <-
	count_and_proportion_per_cmi_by_subsample %>%
	filter(subsample_sz %in% c(100, seq(100,3000,300)))

result_subset_150_to_200 <-
	count_and_proportion_per_cmi_by_subsample %>%
	filter(subsample_sz %in%  c(100, seq(15000,20000,1000)))
summary(count_and_proportion_per_cmi_by_subsample$subsample_sz)

txt_sz <- 14

fac_plot_all <-
  ggplot(result_subset_all, aes(x = cmiRnd, y = proportion)) +
	theme_bw() +
	geom_bar(colour = "black", fill = 'chartreuse4', stat = 'identity') +
	geom_text(aes(label = cmi_n, x = cmiRnd, y = proportion + .05), size = txt_sz - 11) +
  scale_x_continuous(breaks = seq(0, 1, 0.1)) +
  geom_vline(xintercept = 0.7, lty = 2, color = 'red') +
	theme(strip.background = element_blank(),
				strip.text = element_text(size = txt_sz-2),
				axis.title.x = element_text(size = txt_sz),
				axis.text.x = element_text(size = txt_sz - 6),
				axis.title.y = element_text(size = txt_sz + 2),
				axis.text.y = element_text(size = txt_sz - 4)) +
    ylab(paste("proportion of locations in the climate projection")) +
    xlab("composite match index (CMI)") +
    facet_wrap(~subsample_sz, ncol = 3)
fac_plot_all

fac_plot_finer <-
  ggplot(result_subset_finer, aes(x = cmiRnd, y = proportion)) +
	theme_bw() +
	geom_bar(colour = "black", fill = 'chartreuse4', stat = 'identity') +
	geom_text(aes(label = cmi_n, x = cmiRnd, y = proportion + .05), size = txt_sz - 11) +
  scale_x_continuous(breaks = seq(0, 1, 0.1)) +
  geom_vline(xintercept = 0.7, lty = 2, color = 'red') +
	theme(strip.background = element_blank(),
				strip.text = element_text(size = txt_sz-2),
				axis.title.x = element_text(size = txt_sz),
				axis.text.x = element_text(size = txt_sz - 6),
				axis.title.y = element_text(size = txt_sz + 2),
				axis.text.y = element_text(size = txt_sz - 4)) +
    ylab(paste("proportion of locations in the climate projection")) +
    xlab("composite match index (CMI)") +
    facet_wrap(~subsample_sz, ncol = 3)
fac_plot_finer

#--------------------------------------------------------------
# Write facet plots to file
#--------------------------------------------------------------

png(filename = paste(summ_out_dir, facplot_out_fn, sep = '/'),
			 width = 1500,
			height = 700,
				 res = 100)
	fac_plot_all
dev.off()

png(filename = paste(summ_out_dir, facplot_finer_out_fn, sep = '/'),
			 width = 1500,
			height = 700,
				 res = 100)
	fac_plot_finer
dev.off()


#--------------------------------------------------------------
# Box plot overseas CMIs per species
#--------------------------------------------------------------
box_plot_all <-

	ggplot(data = result_subset_all) +
		theme_bw() +
		geom_boxplot(aes(x = subsample_sz, y = cmiRnd, group = subsample_sz), width = 1300, fill = 'chartreuse') +
		coord_cartesian(xlim=c(0,30000)) +
		scale_x_continuous(breaks = seq(0, 30000, 5000)) +
		scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, .2)) +
    geom_hline(yintercept = 0.7, lty = 2, colour = 'red', size = 1) +
		ylab('composite match index (CMI)') +
		xlab("subsample size") +
		theme(axis.text.y = element_text(size = txt_sz),
					axis.title.y = element_text(size = txt_sz),
					axis.text.x = element_text(size = txt_sz),
					axis.title.x = element_text(size = txt_sz))
box_plot_all

summary(result_subset_150_to_200)

box_plot_finer <-

	ggplot(data = result_subset_150_to_200) +
		theme_bw() +
		geom_boxplot(aes(x = subsample_sz, y = cmiRnd, group = subsample_sz), fill = 'chartreuse') +
		coord_cartesian(xlim=c(15000,20000))+
		scale_x_continuous(breaks = seq(15000, 20000, 1000)) +
		scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, .2)) +
    geom_hline(yintercept = 0.7, lty = 2, colour = 'red', size = 1) +
		ylab('composite match index (CMI)') +
		xlab("subsample size") +
		theme(axis.text.y = element_text(size = txt_sz),
					axis.title.y = element_text(size = txt_sz),
					axis.text.x = element_text(size = txt_sz),
					axis.title.x = element_text(size = txt_sz))
box_plot_finer

#--------------------------------------------------------------
# Write box plot plot to file
#--------------------------------------------------------------

png(filename = paste(summ_out_dir, boxplot_out_fn, sep = '/'),
			 width = 600,
			height = 800,
				 res = 100)
	box_plot
dev.off()

#pdf(box_plot, file = 'nz_proj_summary_figures/03_out_box_whisker_plot_of_oseas_cmis_by_sp.pdf')
#	box_plot
#dev.off()
