# ============================================================================
# Simple Flow Cytometry Shiny App
# Using only flowCore and ggplot2 - no external dependencies
# ============================================================================

library(shiny)
library(flowCore)
library(flowWorkspace)
library(ggplot2)

# Define UI
ui <- fluidPage(
  titlePanel("🔬 Flow Cytometry Analysis App"),

  sidebarLayout(
    sidebarPanel(
      h3("Data Input"),

      fileInput("fcsFiles", "Upload FCS Files",
                multiple = TRUE,
                accept = c(".fcs", ".FCS")),

      hr(),

      h3("Visualization"),

      # Sample selector
      uiOutput("sampleSelector"),

      # Channel selectors
      uiOutput("xChannelSelector"),
      uiOutput("yChannelSelector"),

      # Plot options
      sliderInput("pointSize", "Point Size:",
                  min = 0.1, max = 3, value = 0.5, step = 0.1),
      sliderInput("alpha", "Point Transparency:",
                  min = 0.1, max = 1, value = 0.3, step = 0.1),
      checkboxInput("logX", "Log X-axis", value = FALSE),
      checkboxInput("logY", "Log Y-axis", value = FALSE),
      checkboxInput("hexbin", "Use Hexbin (for large datasets)", value = FALSE),

      hr(),

      h3("Export"),
      downloadButton("downloadPlot", "Download Plot"),
      downloadButton("downloadData", "Download Data")
    ),

    mainPanel(
      tabsetPanel(
        tabPanel("Plot",
                 plotOutput("mainPlot", height = "600px", width = "700px")),

        tabPanel("Data Summary",
                 h3("Dataset Overview"),
                 verbatimTextOutput("dataSummary"),
                 h4("Available Channels:"),
                 tableOutput("channelTable")),

        tabPanel("Statistics",
                 h3("Population Statistics"),
                 tableOutput("statsTable")),

        tabPanel("Multi-Sample View",
                 plotOutput("multiSamplePlot", height = "800px", width = "900px")),

        tabPanel("File Diagnostics",
                 h3("FCS File Validation"),
                 p("This tab shows detailed information about uploaded files."),
                 verbatimTextOutput("diagnosticsOutput"),
                 h4("Channel Compatibility:"),
                 verbatimTextOutput("channelCompatibility")),

        tabPanel("About",
                 h3("About This App"),
                 p("A simple Shiny app for flow cytometry data visualization."),
                 h4("Features:"),
                 tags$ul(
                   tags$li("Upload and visualize FCS files"),
                   tags$li("Interactive 2D scatter plots with ggplot2"),
                   tags$li("Multiple samples visualization"),
                   tags$li("Hexbin plots for large datasets"),
                   tags$li("Basic statistics"),
                   tags$li("Export plots and data")
                 ),
                 h4("Built with:"),
                 tags$ul(
                   tags$li("flowCore - FCS file handling"),
                   tags$li("flowWorkspace - Flow cytometry data structures"),
                   tags$li("ggplot2 - Visualization"),
                   tags$li("Shiny - Interactive web interface")
                 ))
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {

  # File validation function
  validateFCS <- function(filepath) {
    tryCatch({
      ff <- read.FCS(filepath, transformation = FALSE, alter.names = TRUE)
      list(
        valid = TRUE,
        filename = basename(filepath),
        events = nrow(ff),
        channels = colnames(ff),
        n_channels = ncol(ff)
      )
    }, error = function(e) {
      list(
        valid = FALSE,
        filename = basename(filepath),
        error = e$message
      )
    })
  }

  # File diagnostics (reactive)
  fileDiagnostics <- reactive({
    req(input$fcsFiles)
    files <- input$fcsFiles$datapath
    names(files) <- input$fcsFiles$name

    withProgress(message = 'Validating files...', value = 0, {
      diagnostics <- lapply(seq_along(files), function(i) {
        result <- validateFCS(files[i])
        result$filename <- names(files)[i]
        incProgress(1 / length(files))
        result
      })
    })

    diagnostics
  })

  # Reactive data loading with channel filtering
  flowData <- reactive({
    req(input$fcsFiles)

    # Read FCS files
    files <- input$fcsFiles$datapath
    names(files) <- input$fcsFiles$name

    withProgress(message = 'Loading FCS files...', value = 0, {
      tryCatch({
        # First, read all files individually to inspect channels
        fs_list <- list()
        all_channels <- list()

        incProgress(0.1, detail = "Reading files...")

        for (i in seq_along(files)) {
          tryCatch({
            ff <- read.FCS(files[i], transformation = FALSE, truncate_max_range = FALSE, alter.names = TRUE)
            fs_list[[names(files)[i]]] <- ff
            all_channels[[i]] <- colnames(ff)
            incProgress(0.4 / length(files))
          }, error = function(e2) {
            showNotification(
              paste("Failed to read", names(files)[i], ":", e2$message),
              type = "error",
              duration = 10
            )
          })
        }

        if (length(fs_list) == 0) {
          stop("Could not read any FCS files. Please check file format.")
        }

        incProgress(0.5, detail = "Finding common channels...")

        # Find common channels across all files
        common_channels <- Reduce(intersect, all_channels)

        if (length(common_channels) == 0) {
          stop("No common channels found across files")
        }

        # Show notification if channels were filtered
        all_unique_channels <- unique(unlist(all_channels))
        if (length(all_unique_channels) > length(common_channels)) {
          filtered_count <- length(all_unique_channels) - length(common_channels)
          showNotification(
            paste("Using", length(common_channels), "common channels.",
                  filtered_count, "unique channels were filtered out."),
            type = "message",
            duration = 5
          )
        }

        incProgress(0.6, detail = "Filtering channels...")

        # Filter each flowFrame to only common channels
        fs_filtered <- lapply(fs_list, function(ff) {
          ff[, common_channels]
        })

        incProgress(0.8, detail = "Creating flowSet...")

        # Convert to flowSet
        fs <- as(fs_filtered, "flowSet")

        incProgress(1, detail = "Done!")
        fs

      }, error = function(e) {
        showNotification(
          paste("Error loading files:", e$message),
          type = "error",
          duration = 10
        )
        NULL
      })
    })
  })

  # Sample selector
  output$sampleSelector <- renderUI({
    req(flowData())
    samples <- sampleNames(flowData())
    selectInput("selectedSample", "Select Sample:",
                choices = samples,
                selected = samples[1])
  })

  # Channel selectors
  output$xChannelSelector <- renderUI({
    req(flowData())
    channels <- colnames(flowData())
    selectInput("xChannel", "X-axis Channel:",
                choices = channels,
                selected = channels[1])
  })

  output$yChannelSelector <- renderUI({
    req(flowData())
    channels <- colnames(flowData())
    selectInput("yChannel", "Y-axis Channel:",
                choices = channels,
                selected = if(length(channels) > 1) channels[2] else channels[1])
  })

  # Get data for current sample
  currentData <- reactive({
    req(flowData(), input$selectedSample)
    fs <- flowData()
    ff <- fs[[input$selectedSample]]
    as.data.frame(exprs(ff))
  })

  # Main plot
  output$mainPlot <- renderPlot({
    req(currentData(), input$xChannel, input$yChannel)

    df <- currentData()

    # Create base plot
    p <- ggplot(df, aes(x = .data[[input$xChannel]], y = .data[[input$yChannel]]))

    if (input$hexbin) {
      p <- p + geom_hex(bins = 100) +
        scale_fill_viridis_c() +
        theme_minimal()
    } else {
      p <- p + geom_point(size = input$pointSize, alpha = input$alpha, color = "steelblue") +
        theme_minimal()
    }

    # Add scales
    if (input$logX) {
      p <- p + scale_x_log10()
    }
    if (input$logY) {
      p <- p + scale_y_log10()
    }

    p <- p +
      labs(title = paste("Sample:", input$selectedSample),
           x = input$xChannel,
           y = input$yChannel) +
      theme(plot.title = element_text(size = 16, face = "bold"))

    print(p)
  })

  # Multi-sample plot
  output$multiSamplePlot <- renderPlot({
    req(flowData(), input$xChannel, input$yChannel)

    fs <- flowData()
    n_samples <- length(fs)

    # Combine all samples into one dataframe
    all_data <- list()
    for(i in 1:n_samples) {
      df <- as.data.frame(exprs(fs[[i]]))
      df$Sample <- sampleNames(fs)[i]
      all_data[[i]] <- df
    }
    combined <- do.call(rbind, all_data)

    # Create faceted plot
    p <- ggplot(combined, aes(x = .data[[input$xChannel]], y = .data[[input$yChannel]])) +
      geom_hex(bins = 50) +
      scale_fill_viridis_c() +
      facet_wrap(~Sample, scales = "free") +
      theme_minimal() +
      labs(title = "Multi-Sample Comparison") +
      theme(plot.title = element_text(size = 16, face = "bold"))

    if (input$logX) p <- p + scale_x_log10()
    if (input$logY) p <- p + scale_y_log10()

    print(p)
  })

  # Data summary
  output$dataSummary <- renderPrint({
    req(flowData())
    fs <- flowData()
    cat("Number of samples:", length(fs), "\n\n")
    cat("Sample names:\n")
    print(sampleNames(fs))
    cat("\nSample dimensions:\n")
    print(fsApply(fs, dim))
  })

  output$channelTable <- renderTable({
    req(flowData())
    fs <- flowData()
    ff <- fs[[1]]
    params <- parameters(ff)

    data.frame(
      Channel = params@data$name,
      Description = params@data$desc,
      stringsAsFactors = FALSE
    )
  })

  # Statistics
  output$statsTable <- renderTable({
    req(flowData())
    fs <- flowData()

    # Get basic statistics for each sample
    stats <- data.frame(
      Sample = sampleNames(fs),
      Total_Events = fsApply(fs, nrow),
      Channels = fsApply(fs, ncol),
      stringsAsFactors = FALSE
    )

    return(stats)
  })

  # Download plot
  output$downloadPlot <- downloadHandler(
    filename = function() {
      paste0("flowcyto_plot_", Sys.Date(), ".png")
    },
    content = function(file) {
      req(currentData(), input$xChannel, input$yChannel)

      df <- currentData()

      p <- ggplot(df, aes(x = .data[[input$xChannel]], y = .data[[input$yChannel]]))

      if (input$hexbin) {
        p <- p + geom_hex(bins = 100) + scale_fill_viridis_c() + theme_minimal()
      } else {
        p <- p + geom_point(size = input$pointSize, alpha = input$alpha, color = "steelblue") +
          theme_minimal()
      }

      if (input$logX) p <- p + scale_x_log10()
      if (input$logY) p <- p + scale_y_log10()

      p <- p + labs(title = paste("Sample:", input$selectedSample),
                    x = input$xChannel, y = input$yChannel)

      ggsave(file, plot = p, width = 10, height = 8, dpi = 300)
    }
  )

  # Download data
  output$downloadData <- downloadHandler(
    filename = function() {
      paste0("flowcyto_data_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(currentData())
      write.csv(currentData(), file, row.names = FALSE)
    }
  )

  # Diagnostics output
  output$diagnosticsOutput <- renderPrint({
    req(fileDiagnostics())
    diag <- fileDiagnostics()

    cat("=== FILE VALIDATION RESULTS ===\n\n")

    for (i in seq_along(diag)) {
      d <- diag[[i]]
      cat(sprintf("File %d: %s\n", i, d$filename))
      cat(sprintf("  Status: %s\n", if(d$valid) "✓ Valid" else "✗ Invalid"))

      if (d$valid) {
        cat(sprintf("  Events: %s\n", format(d$events, big.mark = ",")))
        cat(sprintf("  Channels: %d\n", d$n_channels))
      } else {
        cat(sprintf("  Error: %s\n", d$error))
      }
      cat("\n")
    }
  })

  # Channel compatibility analysis
  output$channelCompatibility <- renderPrint({
    req(fileDiagnostics())
    diag <- fileDiagnostics()

    valid_files <- Filter(function(x) x$valid, diag)

    if (length(valid_files) == 0) {
      cat("No valid files to analyze.\n")
      return()
    }

    all_channels <- lapply(valid_files, function(x) x$channels)
    common_channels <- Reduce(intersect, all_channels)
    all_unique_channels <- unique(unlist(all_channels))

    cat("=== CHANNEL ANALYSIS ===\n\n")
    cat(sprintf("Total unique channels across all files: %d\n", length(all_unique_channels)))
    cat(sprintf("Common channels across all files: %d\n", length(common_channels)))

    if (length(common_channels) > 0) {
      cat("\nCommon channels:\n")
      cat(paste("  -", common_channels, collapse = "\n"))
    }

    # Show file-specific channels
    unique_per_file <- setdiff(all_unique_channels, common_channels)
    if (length(unique_per_file) > 0) {
      cat("\n\nChannels not common to all files:\n")
      cat(paste("  -", unique_per_file, collapse = "\n"))

      cat("\n\nPer-file channel counts:\n")
      for (i in seq_along(valid_files)) {
        f <- valid_files[[i]]
        unique_to_file <- setdiff(f$channels, common_channels)
        cat(sprintf("  %s: %d channels", f$filename, length(f$channels)))
        if (length(unique_to_file) > 0) {
          cat(sprintf(" (%d unique)", length(unique_to_file)))
        }
        cat("\n")
      }
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)
