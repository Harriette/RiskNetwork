
# Define UI for application that draws a histogram
ui <- dashboardPage(
    
    dashboardHeader(title = "Risk Network"),
    
    dashboardSidebar(
        sidebarMenu(
            menuItem("Risks", tabName = "risks", icon = icon("th")),
            menuItem("Network", tabName = "network", icon = icon("project-diagram"))
        )
    ),
            
    dashboardBody(

        shinyjs::useShinyjs(),
        shinyFeedback::useShinyFeedback(),            
        
        tabItems(
            #First tab content
            tabItem(tabName = "risks",
                    risks_table_module_ui("risks_table")     
            ),
            
            #Second tab content
            tabItem(tabName = "network",
                    risk_network_module_ui("risk_network")     
            )
        
        )

    )
    
)


