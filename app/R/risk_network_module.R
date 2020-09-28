# Risks Network Module UI

risk_network_module_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      column(
        width = 9,   
        h1("Network"),
        visNetworkOutput(ns("network"), height = "800px")
      ),
      column(
        class="well",
        width = 3,
        div(class = "option-group",
            checkboxInput(ns("causes"), label = "Highlight causes", value = TRUE),
            checkboxInput(ns("consequences"), label = "Highlight consequences", value = FALSE),
            actionButton(ns("fit"), label = "Fit highlighted in view"),
            actionButton(ns("table_sel"), label = "Highlight table selection"),
            actionButton(ns("table_all"), label = "Highlight all in table")
        )
      )
    )
  )
}


# Risks Network Module Server

risk_network_module <- function(input, output, session) {

  #Load nodes from the risks table
  risks <- reactive({
    session$userData$db_trigger()
    
    out <- NULL
    tryCatch({
      # Join tables to get output needed
      out <- dbGetQuery(conn, "
  SELECT
  	risk_ID AS 'id',
  	risks.name AS 'label',
  	processes.name AS 'process',
  	risks.name AS 'title',
  	rag_rating,
  	loss,
  	description,
  	firms.name AS 'firm',
  	departments.name AS 'department',
  	modified_at,
  	is_deleted
  	FROM risks
  		JOIN firms ON risks.firm_ID = firms.firm_ID
  		JOIN departments ON risks.department_ID = departments.department_ID
  		JOIN processes ON risks.process_ID = processes.process_ID;
                          ")
      
      out <- out %>%
        as_tibble() %>%
        mutate(
          modified_at = as.POSIXct(modified_at, tz = "UTC")
        ) %>%
        # find the most recently modified row for each risk
        group_by(id) %>%
        filter(modified_at == max(modified_at)) %>%
        ungroup() %>%
        # filter out deleted rows
        filter(is_deleted == 0) %>%
        arrange(label)
      
    }, error = function(err) {
      
      print(err)
      showToast("error", "Database Connection Error")
      
    })
    
    out
  })
  
  # Read in edges from the "risklinks" table from the database
  risklinks <- reactive({
    session$userData$db_trigger()
    
    out <- NULL
    tryCatch({
      # Join tables to get output needed
      out <- dbGetQuery(conn, "
  SELECT
  	r1.risk_ID AS 'from',
  	r2.risk_ID AS 'to',
  	risklink_ID,
  	r1.name AS 'risk_from',
  	r2.name AS 'risk_to'
    FROM risklinks
  	  JOIN risks r1 ON risklinks.riskfrom_ID = r1.uuid
  	  JOIN risks r2 ON risklinks.riskto_ID = r2.uuid;
                          ")
      
      out <- out %>%
        as_tibble()
      
    }, error = function(err) {
      
      print(err)
      showToast("error", "Database Connection Error")
      
    })
    
    out
  })
  
  # Function to highlight linked nodes
  which_nodes <- function(root_node){
    
    #If no starting node, return
    if(is.null(root_node)) return()
    
    highlight_risks <- root_node
    if (input$causes4) {
      causes <- unlist(lapply(root_node, function(x){
        unique(unlist(all_simple_paths(net, from=x, mode="in")))
      }))
      #causes <- all_simple_paths(net, input$risk_network4_selected, mode = "in")
      highlight_risks <- c(highlight_risks, causes)        
    }
    if (input$consequences4) {
      consequenses <- unlist(lapply(root_node, function(x){
        unique(unlist(all_simple_paths(net, from=x, mode="out")))
      }))
      highlight_risks <- c(highlight_risks, consequenses)    
    }
    
    return(unique(highlight_risks))
    
  }
  
  # Output network
  output$network <- renderVisNetwork({
    
    nodes <- risks()
    edges <- risklinks()
    net <- graph_from_data_frame(d=edges, vertices=nodes, directed=T) 
    
    # filter out unwanted columns
    nodes <- nodes %>%
      select(id, label, process, title,
             rag_rating,
             loss, description,
             firm, department) %>%
      # Make losses their own separate group
      mutate(group = ifelse(loss==1, "loss", process))
    
    visNetwork(nodes, edges) %>%
      visNodes() %>%
      visEdges(arrows = "to") %>%
      visGroups(
        groupname = "loss",
        shape = "icon",
        icon = list(code = "f05b", size = 75, color = "red") #f05b
      ) %>%
      visOptions(
        nodesIdSelection = list(
          enabled = TRUE,
          style = 'visibility: hidden'
        ),
        highlightNearest = list(
          enabled = TRUE,
          hover = FALSE,
          algorithm = "hierarchical",
          degree = list(from = ifelse(input$causes, nrow(nodes), 0),
                        to = ifelse(input$consequences, nrow(nodes), 0)
          ),
          labelOnly = FALSE
        )
      ) %>%
      visHierarchicalLayout(
        enabled = TRUE,
        direction = "LR",
        levelSeparation = 250,
        sortMethod = "directed"
      ) %>%
      visInteraction(
        tooltipStyle = paste0(
          "position: fixed; visibility:hidden; ",
          "width:200px; padding: 5px; ",
          "background-color: #efedb8; border-radius: 6px;"
        )
      ) %>%
      addFontAwesome()
    
  })
  
}



