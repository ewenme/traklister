# load packages
library(shiny)
library(clipr)
library(rclipboard)
library(xml2)

# helper functions
read_traktor_history <- function(file) {
    
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
    
    return(attrs)
    
}


ui <- fluidPage(
    
    includeCSS("styles.css"),
    
    rclipboardSetup(),
    
    fluidRow(
        column(
            3,
            # title
            h2("traks"),
            HTML(paste("<p>Convert <a href='https://www.native-instruments.com/en/products/traktor/'>Traktor</a> .nml playlists",
                       "into a plain-text format.</p>")),
            # file upload
            fileInput("uploadData", NULL,
                      accept = c(".nml"), buttonLabel = "browse",
                      placeholder = "no file selected", multiple = FALSE),
            p("Tweak the formatting."),
            checkboxInput("trackNo", label = "Track #", value = FALSE),
            p("Export or copy the tracklist."),
            fluidRow(
                column(2, 
            # d/l button
            downloadButton("downloadData", label = NULL)
            ),
            column(2, 
            # UI ouputs for the copy-to-clipboard buttons
            uiOutput("clip")
            )),
            HTML(paste("<p>Made by <a href='https://twitter.com/ewen_'>@ewen_</a>.",
                       "Peep the <a href='https://github.com/ewenme/tracklister'>code</a>.</p>"))
            ),
        column(
            9,
            verbatimTextOutput("tracklist")
            )
        )
    )

server <- function(input, output) {
    
    # read file as df
    track_df <- reactive({
        
        # check for upload
        upload <- input$uploadData
        if (is.null(upload)) return(NULL)
        
        # filenames object
        read_traktor_history(file = upload$name)

    })
    
    # convert df to text format
    track_text <- reactive({
        
        df <- track_df()
        
        if (input$trackNo) {
            
            paste0(df$track_no, " ", df$artist, " - ", df$title, " [", df$label, "]", collapse = "\n")
            
        } else {
            paste0(df$artist, " - ", df$title, " [", df$label, "]", collapse = "\n")
        }
        
    })

    # view preview output of uploaded file
    output$tracklist <- renderText({
        
        req(input$uploadData)
        
        track_text()
        
    })
    
    # downloadable .txt of tracklist
    output$downloadData <- downloadHandler(
        filename = function() {
            paste(format(Sys.Date(), "%d%m%y"), ".txt", sep = "")
        },
        content = function(file) {
            write.table(track_df(), file, 
                        quote = FALSE, sep = " ", na = " ", 
                        row.names = FALSE, col.names = FALSE)
        }
    )
    
    # Add clipboard buttons
    output$clip <- renderUI({
        rclipButton("copyData", label = NULL, track_text(), icon("clipboard"))
    })
    
    # Workaround for execution within RStudio
    observeEvent(input$copyData, write_clip(track_text()))
}

# Run the application 
shinyApp(ui = ui, server = server)
