
# Define UI for application that draws a histogram
ui <- dashboardPage(
    
    dashboardHeader(title = "Risk Network"),
    
    dashboardSidebar(
        sidebarMenu(
            menuItem("Risks", tabName = "risks", icon = icon("th"))
        )
    ),
            
    dashboardBody(

        shinyjs::useShinyjs(),
        shinyFeedback::useShinyFeedback(),            
        
        tabItems(
            #First tab content
            tabItem(tabName = "risks",
                    risks_table_module_ui("risks_table")     
            )
        
        )

    )
    
)


