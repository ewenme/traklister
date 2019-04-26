library(shiny)
library(xml2)
library(magrittr)

read_traktor_history <- function(file) {
    
    # read file
    traktor_history <- read_xml(x = file)
    
    # parse xml tree
    entries <- xml_child(traktor_history, search = 3) %>%
        xml_find_all(xpath = ".//ENTRY")
    
    info <- xml_find_first(entries, xpath = ".//INFO")
    
    # extract key attrs
    attrs <- data.frame(
        track_no = seq_along(entries),
        artist = xml_attr(entries, "ARTIST"),
        title = xml_attr(entries, "TITLE"),
        label = xml_attr(info, "LABEL"),
        stringsAsFactors = FALSE
    )
    
    return(attrs)
    
}

ui <- fluidPage(

    # Application title
    titlePanel("tracklister"),

    # Sidebar
    sidebarLayout(
        sidebarPanel(
            
            # file upload
            fileInput("uploadData", "Upload a file:",
                      accept = c(".nml"), buttonLabel = "browse",
                      placeholder = "no file selected", multiple = FALSE),
            
            # d/l button
            downloadButton("downloadData", "Download")
        ),

        # Show a plot of the generated distribution
        mainPanel(
           tableOutput("table")
        )
    )
)

server <- function(input, output) {
    
    # read file
    track_data <- reactive({
        
        # check for upload
        upload <- input$uploadData
        if (is.null(upload)) return(NULL)
        
        # filenames object
        read_traktor_history(file = upload$name)

    })

    # view table of uploaded file
    output$table <- renderTable({
        track_data()
    })
    
    # downloadable .txt of tracklist
    output$downloadData <- downloadHandler(
        filename = function() {
            paste(format(Sys.Date(), "%d%m%y"), ".txt", sep = "")
        },
        content = function(file) {
            write.table(track_data(), file, 
                        quote = FALSE, sep = " ", na = "", 
                        row.names = FALSE, col.names = FALSE)
        }
    )
}

# Run the application 
shinyApp(ui = ui, server = server)
