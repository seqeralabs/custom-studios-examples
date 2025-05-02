library(shiny)
library(ggplot2)
library(dplyr)

# Define UI
ui <- fluidPage(
    # Custom CSS for better styling
    tags$head(
        tags$style(HTML("
            body { background-color: #f5f5f5; }
            .well { background-color: white; border-radius: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            .panel { border-radius: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            .panel-heading { border-radius: 10px 10px 0 0; }
            .btn-primary { background-color: #4a90e2; border-color: #4a90e2; }
            .btn-primary:hover { background-color: #357abd; border-color: #357abd; }
        "))
    ),
    
    # Title panel
    titlePanel("Advanced Data Visualization"),
    
    # Sidebar layout
    sidebarLayout(
        sidebarPanel(
            # Data source message at the top
            div(style = "margin-bottom: 20px; padding: 10px; background-color: #e8f4f8; border-radius: 5px;",
                textOutput("data_source")
            ),
            
            # Plot type selection
            selectInput("plot_type", "Select Plot Type:",
                       choices = c("Scatter Plot" = "scatter",
                                 "Line Plot" = "line",
                                 "Bar Plot" = "bar",
                                 "Box Plot" = "box",
                                 "Density Plot" = "density"),
                       selected = "scatter"),
            
            # Color theme selection
            selectInput("color_theme", "Select Color Theme:",
                       choices = c("Default" = "default",
                                 "Viridis" = "viridis",
                                 "Brewer Blues" = "blues",
                                 "Brewer Reds" = "reds"),
                       selected = "default"),
            
            # Additional controls based on plot type
            conditionalPanel(
                condition = "input.plot_type == 'scatter'",
                sliderInput("point_size", "Point Size:", min = 1, max = 10, value = 3),
                checkboxInput("add_trend", "Add Trend Line", value = TRUE)
            ),
            
            conditionalPanel(
                condition = "input.plot_type == 'line'",
                sliderInput("line_width", "Line Width:", min = 0.5, max = 3, value = 1),
                checkboxInput("add_points", "Add Points", value = TRUE)
            ),
            
            conditionalPanel(
                condition = "input.plot_type == 'bar'",
                sliderInput("bar_width", "Bar Width:", min = 0.1, max = 1, value = 0.7),
                checkboxInput("add_error_bars", "Add Error Bars", value = TRUE)
            ),
            
            conditionalPanel(
                condition = "input.plot_type == 'box'",
                checkboxInput("add_points", "Add Points", value = TRUE),
                checkboxInput("add_violin", "Add Violin Plot", value = FALSE)
            ),
            
            conditionalPanel(
                condition = "input.plot_type == 'density'",
                sliderInput("bandwidth", "Bandwidth:", min = 0.1, max = 2, value = 0.5),
                checkboxInput("add_rug", "Add Rug Plot", value = TRUE)
            ),
            
            # Summary statistics panel
            div(style = "margin-top: 20px;",
                h4("Summary Statistics"),
                verbatimTextOutput("summary_stats")
            )
        ),
        
        # Main panel
        mainPanel(
            # Plot output
            plotOutput("plot", height = "500px"),
            
            # Data table
            div(style = "margin-top: 20px;",
                h4("Data Table"),
                dataTableOutput("data_table")
            )
        )
    )
)

# Define server logic
server <- function(input, output, session) {
    # Read data
    data <- reactive({
        file_path <- '/workspace/data/shiny-inputs/data.csv'
        if (file.exists(file_path)) {
            read.csv(file_path)
        } else {
            # Fallback to built-in data
            data.frame(
                x = 1:50,
                y = rnorm(50, mean = 50, sd = 10)
            )
        }
    })
    
    # Data source message
    output$data_source <- renderText({
        file_path <- '/workspace/data/shiny-inputs/data.csv'
        if (file.exists(file_path)) {
            "Using external data file"
        } else {
            "Using built-in random data"
        }
    })
    
    # Summary statistics
    output$summary_stats <- renderPrint({
        summary(data()$y)
    })
    
    # Create plot
    output$plot <- renderPlot({
        df <- data()
        
        # Base plot
        p <- ggplot(df, aes(x = x, y = y))
        
        # Add plot elements based on selection
        if (input$plot_type == "scatter") {
            p <- p + geom_point(size = input$point_size, aes(color = "Data Points"))
            if (input$add_trend) {
                p <- p + geom_smooth(method = "lm", se = TRUE, aes(color = "Trend Line"))
            }
        } else if (input$plot_type == "line") {
            p <- p + geom_line(size = input$line_width, aes(color = "Line"))
            if (input$add_points) {
                p <- p + geom_point(aes(color = "Points"))
            }
        } else if (input$plot_type == "bar") {
            p <- p + geom_bar(stat = "identity", width = input$bar_width, aes(fill = "Bars"))
            if (input$add_error_bars) {
                p <- p + stat_summary(fun.data = mean_se, geom = "errorbar", width = 0.2, aes(color = "Error Bars"))
            }
        } else if (input$plot_type == "box") {
            p <- p + geom_boxplot(aes(fill = "Box Plot"))
            if (input$add_points) {
                p <- p + geom_jitter(width = 0.2, aes(color = "Points"))
            }
            if (input$add_violin) {
                p <- p + geom_violin(alpha = 0.3, aes(fill = "Violin"))
            }
        } else if (input$plot_type == "density") {
            p <- p + geom_density(adjust = input$bandwidth, aes(fill = "Density"))
            if (input$add_rug) {
                p <- p + geom_rug(aes(color = "Rug"))
            }
        }
        
        # Apply color theme
        if (input$color_theme == "viridis") {
            p <- p + scale_color_viridis_d() + scale_fill_viridis_d()
        } else if (input$color_theme == "blues") {
            p <- p + scale_color_brewer(palette = "Blues") + scale_fill_brewer(palette = "Blues")
        } else if (input$color_theme == "reds") {
            p <- p + scale_color_brewer(palette = "Reds") + scale_fill_brewer(palette = "Reds")
        } else {
            # Default theme
            p <- p + scale_color_brewer(palette = "Set1") + scale_fill_brewer(palette = "Set1")
        }
        
        # Add labels and theme
        p <- p + 
            labs(title = paste("Data Visualization:", input$plot_type),
                 x = "X", y = "Y") +
            theme_minimal() +
            theme(
                plot.title = element_text(size = 16, face = "bold"),
                axis.title = element_text(size = 12),
                axis.text = element_text(size = 10),
                panel.grid.major = element_line(color = "gray90"),
                panel.grid.minor = element_line(color = "gray95")
            )
        
        p
    })
    
    # Data table
    output$data_table <- renderDataTable({
        data()
    })
}

# Run the app
shinyApp(ui = ui, server = server) 