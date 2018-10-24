fGetIndicesOfCharInString <- function(a_string, the_chars) {
	unlist(lapply(strsplit(a_string, ''), function(x) grep(the_chars, x)))
}

