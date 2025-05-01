library(shiny)

# Define UI
ui <- fluidPage(
    titlePanel("Interactive Plotting Demo"),
    sidebarLayout(
        sidebarPanel(
            # File upload
            fileInput("file", "Upload CSV File (Optional)",
                     accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv")),
            
            # Plot type selector
            selectInput("plotType", "Select Plot Type:",
                       choices = c("Scatter Plot" = "scatter",
                                 "Bar Plot" = "bar",
                                 "Line Plot" = "line")),
            
            # Color selector
            selectInput("color", "Select Color:",
                       choices = c("Blue" = "blue",
                                 "Red" = "red",
                                 "Green" = "green",
                                 "Purple" = "purple")),
            
            # Point size for scatter plot
            conditionalPanel(
                condition = "input.plotType == 'scatter'",
                sliderInput("pointSize", "Point Size:",
                           min = 1, max = 5, value = 2)
            ),
            
            # Number of points/bars (only show if no file is uploaded)
            conditionalPanel(
                condition = "!input.file",
                sliderInput("nPoints", "Number of Points/Bars:",
                           min = 10, max = 100, value = 30)
            )
        ),
        
        mainPanel(
            plotOutput("plot")
        )
    )
)

# Define server logic
server <- function(input, output) {
    # Generate or load data based on user input
    data <- reactive({
        if (!is.null(input$file)) {
            # Read uploaded file
            df <- read.csv(input$file$datapath)
            # Ensure required columns exist
            if (!all(c("x", "y") %in% names(df))) {
                stop("Uploaded file must contain 'x' and 'y' columns")
            }
            return(df)
        } else {
            # Generate default data
            n <- input$nPoints
            x <- seq(1, n)
            y <- switch(input$plotType,
                       "scatter" = rnorm(n, mean = 50, sd = 10),
                       "bar" = sample(1:100, n),
                       "line" = sin(x/5) * 20 + 50 + rnorm(n, sd = 2))
            return(data.frame(x = x, y = y))
        }
    })
    
    # Create the plot
    output$plot <- renderPlot({
        df <- data()
        
        # Base plot
        plot(df$x, df$y,
             type = switch(input$plotType,
                          "scatter" = "p",
                          "bar" = "h",
                          "line" = "l"),
             col = input$color,
             pch = 16,
             cex = if(input$plotType == "scatter") input$pointSize else 1,
             xlab = "X-axis",
             ylab = "Y-axis",
             main = paste("Interactive", 
                         switch(input$plotType,
                                "scatter" = "Scatter Plot",
                                "bar" = "Bar Plot",
                                "line" = "Line Plot")))
        
        # Add grid
        grid()
    })
}

# Run the app
shinyApp(ui = ui, server = server) 