#' Run contained Shiny app in a web browser
#' 
#' \code{traklister} provides an interactive tool to parse Traktor playlists
#' more easily. The tool will be launched in a web browser.
#' @export
launch <- function() {
  shiny::runApp(system.file("shiny", package = "traklister"),
                display.mode = "normal",
                launch.browser = TRUE)
}