fGetColorsToPlotAClimexMcrProjection <- function(cmi_integer_vector) {

	# library(RColorBrewer) # for brewer.pal
	# display.brewer.all()
  #	cols <- brewer.pal(n = 11, name = "RdYlGn")

	cols <- c('#A50026', '#D73027', '#F46D43', '#FDAE61', '#FEE08B', '#FFFFBF', '#D9EF8B', '#A6D96A', '#66BD63', '#1A9850', '#006837')

	cols <- rev(cols)

	col_index <- paste(sort(unique(cmi_integer_vector)) * 10)
#	col_index <- paste(sort(cmi_integer_vector) * 10)

	col_index <- as.numeric(col_index)

	cols <- cols[col_index]

	return(cols)

}
