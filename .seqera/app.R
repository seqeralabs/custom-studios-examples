# Change to the application directory
# setwd("data/nf-core-differentialabundance-results/shinyngs_app/study/")

# Load required libraries
library(shiny)
library(markdown)

# Load RNA-seq dataset from an RDS file
esel <- readRDS("data.rds")

# Prepare the Shiny app using the loaded RNA-seq dataset
app <- prepareApp("rnaseq", esel)

# Launch the Shiny application
shiny::shinyApp(app$ui, app$server)


