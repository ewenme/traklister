#' Parse a Traktor .nml file
#' @param file path to a .nml file
#' @export
parse_traktor_nml <- function(file) {
  
  # read file
  traktor_history <- read_xml(x = file)
  
  # parse xml tree
  entries <- xml_find_all(xml_child(traktor_history, search = 3), xpath = ".//ENTRY")
  
  info <- xml_find_first(entries, xpath = ".//INFO")
  
  # extract key attrs
  attrs <- data.frame(
    track_no = sprintf("%02d.", seq_along(entries)),
    artist = xml_attr(entries, "ARTIST"),
    title = xml_attr(entries, "TITLE"),
    label = xml_attr(info, "LABEL")
  )
  
  # rm whitespace
  attrs <- as.data.frame(lapply(attrs, trimws), stringsAsFactors = FALSE)
  
  # replace missing vals w blanks
  attrs[is.na(attrs)] <- " "
  
  # bracket label
  attrs$label <- paste0("[", attrs$label, "]")
  
  # create artist / title combo
  attrs$artist_title = paste(attrs$artist, "-", attrs$title)
  
  return(attrs)
  
}