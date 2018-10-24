---
author: Mariona
date: 22/10/2018
description: Script to explore the effect of the number of AWAY locations
---

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

rdata_read_dir <-  './rdata_out_files'
details = file.info(list.files(rdata_read_dir, pattern="*.RData",full.names = TRUE)) ## extract the metadata of all files in r_data_dir
rdata_read_fn <- row.names(details[rev(order(details$mtime)),])[1] ## select the most recently modified

summ_out_dir <-  './nz_proj_summarised'
if (!dir.exists(summ_out_dir)) dir.create(summ_out_dir)

facplot_all_out_fn <- paste0('04_out_cmis_fac_by_all_subsample_',Sys.Date(),'.png') # facet plot with all data
facplot_zoom_out_fn <- paste0('04_out_cmis_fac_by_zoom_subsample_',Sys.Date(),'.png') # facet plot with
boxplot_all_out_fn <- paste0('04_out_cmis_boxplot_by_all_subsample_',Sys.Date(),'.png') # box plot with all data
boxplot_zoom_out_fn <- paste0('04_out_cmis_boxplot_by_zoom_subsample_',Sys.Date(),'.png') # box plot

#---------------------------------------------------------
# Load CMI data
#---------------------------------------------------------
#load(rdata_read_fn) # proj_comp
load('./rdata_out_files/04_out_nz_proj_cmis_17September2018.RData')
tail(proj_comp)

proj_comp$subsample_sz <- proj_comp$subsample_sz * 100
head(proj_comp)

summary(proj_comp$subsample_sz)

length(unique(proj_comp$subsample_sz))

length(unique(proj_comp$BestKey)) # How many different overseas points are used to calculate the NZ projections
# Only 684 AWAY locations
length(unique(proj_comp$Loc1Key))
length(unique(proj_comp$BestLat))
dim(proj_comp)
#--------------------------------------------------------------
# Summarise results for NZ CMI maps from each subsample size
#--------------------------------------------------------------
table(proj_comp$cmiRnd)
chk <- filter(proj_comp, cmiRnd < 0 | cmiRnd > 1)
#View(chk)

# Extract Influential AWAY points
points <- proj_comp[,c(5,10)]
iap_per_samplesize <-as.data.frame(colSums(table(points) != 0))
iap_per_samplesize$sample_size <- as.numeric(row.names(iap_per_samplesize))
colnames(iap_per_samplesize)[1] <- 'n'

str(iap_per_samplesize)


# Extract basic stats
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

# Extract
count_and_proportion_per_cmi_by_subsample <-
	proj_comp %>%
		group_by(subsample_sz, cmiRnd) %>%
		summarise(cmi_n = length(Loc1Key)) %>%
		mutate(proportion = round(cmi_n/cmis_per_subsample, 4))

head(count_and_proportion_per_cmi_by_subsample, n = 20)
save(count_and_proportion_per_cmi_by_subsample, file = paste(summ_out_dir, 'count_and_proportion_per_cmi_by_subsample.RData', sep = '/'))

#--------------------------------------------------------------
# Descriptive statistics of all data
#--------------------------------------------------------------

lm_meanCMI_samplesize <-
ggplot(data = cmi_min_max_mean_sd_by_subsample, aes(x = subsample_sz, y = mean_cmi)) +
  labs(title = 'Increase of mean CMI value with sample size', y = 'mean CMI', x = 'Number of AWAY presence points used for projection')+
	geom_point(color='green') +
  geom_smooth(method = "lm", se = FALSE)

png(filename = paste(summ_out_dir, 'lm_meancMI_samplesize.png', sep = '/'),
				width = 1500,
				height = 700,
					 res = 100)
		lm_meanCMI_samplesize
dev.off()

min(cmi_min_max_mean_sd_by_subsample$subsample_sz)
plot(cmi_min_max_mean_sd_by_subsample$subsample_sz)

lm_sdCMI_samplesize <-
ggplot(data = cmi_min_max_mean_sd_by_subsample, aes(x = subsample_sz, y = sd_cmi)) +
	labs( title = 'Dispersion of CMI value with increasing sample size', y = 'SD of CMI values', x = 'Number of AWAY presence points used for projection')+
	geom_point(color='green') +
  geom_smooth(method = "lm", se = FALSE)

png(filename = paste(summ_out_dir, 'lm_sdCMI_samplesize.png', sep = '/'),
				width = 1500,
				height = 700,
					res = 100)
		lm_sdCMI_samplesize
	dev.off()

head(iap_per_samplesize)

influential_AWAY_points_scatterplot <-
  ggplot(iap_per_samplesize, aes(x = sample_size,y = n)) +
 	geom_point(color = 'darkturquoise') +
	labs( title = 'Influential AWAY points', y = 'Number of influential AWAY locations', x = 'Sample size')

	png(filename = paste(summ_out_dir, 'influential_AWAY_points_scatterplot.png', sep = '/'),
					width = 1500,
					height = 700,
						res = 100)
			influential_AWAY_points_scatterplot
		dev.off()

#--------------------------------------------------------------
# Subsample the data for analysis
#--------------------------------------------------------------

length(unique(count_and_proportion_per_cmi_by_subsample$subsample_sz)) # 1000
summary(count_and_proportion_per_cmi_by_subsample$subsample_sz) # range 100 to 1000000

# There are 1000 different subsample sizes. For plotting, just take a subsample
# Subsample that covers the whole range ( from n=100 to n=100000)
result_subset_all<-
	count_and_proportion_per_cmi_by_subsample %>%
	filter(subsample_sz %in% c(100, seq(2500, 100000, 10000)))

# Subsample to investigate what happens between n=100 and n=2500 which seems to be already stable.
result_subset_zoom <-
	count_and_proportion_per_cmi_by_subsample %>%
	filter(subsample_sz %in% c(100, seq(100,3000,500)))

result_subset_150_to_200 <-
	count_and_proportion_per_cmi_by_subsample %>%
	filter(subsample_sz %in%  c(100, seq(15000,20000,1000)))
summary(count_and_proportion_per_cmi_by_subsample$subsample_sz)

#--------------------------------------------------------------
# Facet plot CMI proportions per species.
#--------------------------------------------------------------

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


fac_plot_zoom <-
  ggplot(result_subset_zoom, aes(x = cmiRnd, y = proportion)) +
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
fac_plot_zoom

#--------------------------------------------------------------
# Write facet plots to file
#--------------------------------------------------------------

png(filename = paste(summ_out_dir, facplot_all_out_fn, sep = '/'),
			 width = 1500,
			height = 700,
				 res = 100)
	fac_plot_all
dev.off()

png(filename = paste(summ_out_dir, facplot_zoom_out_fn, sep = '/'),
			 width = 1500,
			height = 700,
				 res = 100)
	fac_plot_zoom
dev.off()


#--------------------------------------------------------------
# Box plot overseas CMIs per species
#--------------------------------------------------------------
box_plot_all <-

	ggplot(data = result_subset_all) +
		theme_bw() +
		geom_boxplot(aes(x = subsample_sz, y = cmiRnd, group = subsample_sz), width = 1300, fill = 'chartreuse') +
		coord_cartesian(xlim=c(100,100000)) +
		scale_x_continuous(breaks = seq(100, 100000, 5000)) +
		scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, .2)) +
    geom_hline(yintercept = 0.7, lty = 2, colour = 'red', size = 1) +
		ylab('composite match index (CMI)') +
		xlab("subsample size") +
		theme(axis.text.y = element_text(size = txt_sz),
					axis.title.y = element_text(size = txt_sz),
					axis.text.x = element_text(angle = 45, size = txt_sz),
					axis.title.x = element_text(size = txt_sz))
box_plot_all

box_plot_all <-

	ggplot(data = count_and_proportion_per_cmi_by_subsample) +
		theme_bw() +
		geom_boxplot(aes(x = subsample_sz, y = cmiRnd, group =  cut_width(subsample_sz, 5000)), fill = 'chartreuse') +
		geom_smooth(method = "lm", se=FALSE, color="black", formula = cmiRnd ~ subsample_sz)+
		coord_cartesian(xlim=c(100,100000)) +
		#scale_x_discrete(labels = seq(100,100000,10000)) +
		scale_x_continuous(breaks = seq(100, 100000, 10000)) +
		scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, .2)) +
    geom_hline(yintercept = 0.7, lty = 2, colour = 'red', size = 1) +
		ylab('composite match index (CMI)') +
		xlab("subsample size") +
		#stat_summary(fun.y = median, geom="line", aes(group=subsample_sz), size=2) +
		theme(axis.text.y = element_text(size = txt_sz),
					axis.title.y = element_text(size = txt_sz),
					axis.text.x = element_text(size = txt_sz),
					axis.title.x = element_text(size = txt_sz))
box_plot_all



box_plot_zoom <-

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
box_plot_zoom

#--------------------------------------------------------------
# Write box plot plot to file
#--------------------------------------------------------------

png(filename = 'Boxplot_all.png',
			 width = 600,
			height = 800,
				 res = 100)
	box_plot_all
dev.off()

#pdf(box_plot, file = 'nz_proj_summary_figures/03_out_box_whisker_plot_of_oseas_cmis_by_sp.pdf')
#	box_plot
#dev.off()
