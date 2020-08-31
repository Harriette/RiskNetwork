library(RMariaDB)
library(shinydashboard)
library(shiny)
library(DBI)
library(config)
library(DT)
library(shinyjs)
library(shinycssloaders)
library(shinyFeedback)
library(dplyr)
library(lubridate)

dw <- config::get()

conn <- dbConnect(drv=dw$drv, 
                 user=dw$user, 
                 password=dw$password,
                 host=dw$host, 
                 port=dw$port,
                 dbname=dw$dbname)

shiny::onStop(function() {
    dbDisconnect(conn)
})

# Turn off scientific notation
options(scipen = 999)

# Set spinner type (for loading)
options(spinner.type = 8)

# Set max rating (assume min is always 1)
max_rating_prob <- 5
max_rating_severity <- 5

# Set RAG options for risks
rag_options <- c('', 'Red', 'Amber', 'Green')


