
server <- function(input, output, session) {
  
  # user session$userData to store user data that will be needed throughout
  # the Shiny application
  session$userData$email <- 'myname@me.com'
  session$userData$db_trigger <- reactiveVal(0)
  
  moduleServer("risk_network", risk_network_module)
  moduleServer("risks_table", risks_table_module)
  
    
}