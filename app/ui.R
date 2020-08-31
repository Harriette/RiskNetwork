
# Define UI for application that draws a histogram
ui <- dashboardPage(
    
    dashboardHeader(title = "Risk Network"),
    
    dashboardSidebar(textInput("text", "Text")),
            
    dashboardBody(
        shinyjs::useShinyjs(),
        shinyFeedback::useShinyFeedback(),

        risks_table_module_ui("risks_table")
    )
    
)


