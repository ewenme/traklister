# load packages
library(shiny)
library(clipr)
library(rclipboard)
library(xml2)
library(traklister)

ui <- fluidPage(
    
    includeCSS("www/styles.css"),
    
    rclipboardSetup(),
    
    fluidRow(
        column(
            3,
            # title
            h2("traklister"),
            HTML(paste("<p>Convert <a href='https://en.wikipedia.org/wiki/Traktor'>Traktor</a> .nml playlists",
                       "into a plain-text format.</p>")),
            # file upload
            fileInput("uploadData", NULL,
                      accept = c(".nml"), buttonLabel = "browse",
                      placeholder = "no file selected", multiple = FALSE),
            conditionalPanel(condition = "output.config_cond == false",
            p("Tweak the formatting."),
            checkboxGroupInput("trackFields", label = NULL, inline = TRUE,
                               choiceNames = list("track #", "artist / title", "label"), 
                               choiceValues = list("track_no", "artist_title", "label"),
                               selected = list("track_no", "artist_title", "label")),
            p("Export the tracklist as .txt, or copy it to your clipboard."),
            fluidRow(
                column(2, 
            # d/l button
            downloadButton("downloadData", label = NULL)
            ),
            column(2, 
            # UI ouputs for the copy-to-clipboard buttons
            uiOutput("clip")
            ))),
            HTML(paste("<p>Made by <a href='https://twitter.com/ewen_'>@ewen_</a>.",
                       "Peep the <a href='https://github.com/ewenme/traklister'>code</a>.</p>"))
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
        parse_traktor_nml(file = upload$name)

    })
    
    # convert df to text format
    track_text <- reactive({
        
        req(input$uploadData, input$trackFields)
        
        df <- track_df()
        
        do.call(paste, c(df[input$trackFields], collapse = "\n"))
        
    })

    # view preview output of uploaded file
    output$tracklist <- renderText({
        
        req(input$uploadData)
        
        track_text()
        
    })
    
    # condition to use in the config conditional UI
    output$config_cond <- reactive({
        is.null(input$uploadData)
    })
    outputOptions(output, "config_cond", suspendWhenHidden = FALSE)
    
    # downloadable .txt of tracklist
    output$downloadData <- downloadHandler(
        filename = function() {
            paste(format(Sys.Date(), "%d%m%y"), ".txt", sep = "")
        },
        content = function(file) {
            fileConn <- file(file)
            writeLines(track_text(), fileConn)
            close(fileConn)
        }
    )
    
    # add clipboard buttons
    output$clip <- renderUI({
        rclipButton("copyData", label = NULL, track_text(), icon("clipboard"))
    })
    
    # Workaround for execution within RStudio
    observeEvent(input$copyData, write_clip(track_text()))
}

shinyApp(ui = ui, server = server)
