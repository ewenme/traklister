# parse a Traktor .nml file
parse_traktor_nml <- function(file) {
  
  # read file
  traktor_history <- read_xml(x = file)
  
  # parse collection entries
  collection_entries <- xml_find_all(xml_child(traktor_history, search = "COLLECTION"), xpath = ".//ENTRY")

  # parse entries info
  collection_entries_info <- xml_find_first(collection_entries, xpath = ".//INFO")
  
  # parse locations
  collection_locations <- xml_find_all(collection_entries, xpath = ".//LOCATION")
  
  collection_locations <- paste0(xml_attr(collection_locations, "VOLUME"), 
                                 xml_attr(collection_locations, "DIR"),
                                 xml_attr(collection_locations, "FILE"))
  
  # parse playlist entries
  playlist_entries <- xml_find_all(xml_child(traktor_history, search = "PLAYLISTS"), 
                                   xpath = ".//ENTRY")
  
  # isolate playlist keys
  playlist_keys <- xml_attr(xml_child(playlist_entries, search = "PRIMARYKEY"), attr = "KEY")
  
  # collection data frame
  collection_df <- data.frame(
    artist = xml_attr(collection_entries, "ARTIST"),
    title = xml_attr(collection_entries, "TITLE"),
    label = xml_attr(collection_entries_info, "LABEL"),
    location = collection_locations
  )
  
  # playlist data frame
  playlist_df <- data.frame(
    track_no_num = seq_along(playlist_keys),
    track_no = sprintf("%02d.", seq_along(playlist_keys)),
    location = playlist_keys
  )
  
  # join df
  df <- merge(playlist_df, collection_df, by = "location", sort = FALSE)
  
  # sort by track no
  df <- df[order(df$track_no_num),]
  
  # rm unused cols
  df$location <- NULL
  df$track_no_num <- NULL
  
  # rm whitespace
  df <- as.data.frame(lapply(df, trimws), stringsAsFactors = FALSE)
  
  # replace missing vals w blanks
  df[is.na(df)] <- " "
  
  # bracket label
  df$label <- paste0("[", df$label, "]")
  
  # create artist / title combo
  df$artist_title = paste(df$artist, "-", df$title)
  
  return(df)
  
}
