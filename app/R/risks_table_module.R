# Risks Table Module UI

risks_table_module_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      column(
        width = 2,
        actionButton(
          ns("add_risk"),
          "Add",
          class = "btn-success",
          style = "color: #fff;",
          icon = icon('plus'),
          width = '100%'
        ),
        tags$br(),
        tags$br()
      )
    ),
    fluidRow(
      column(
        width = 12,
        title = "Risks",
        DTOutput(ns('risks_table')) %>%
          withSpinner(),
        tags$br(),
        tags$br()
      )
    ),
    tags$script(src = "risks_table_module.js"),
    tags$script(paste0("risks_table_module_js('", ns(''), "')"))
  )
}


# Risks Table Module Server

risks_table_module <- function(input, output, session) {
  
  # Read in "risks" table from the database
  risks <- reactive({
    session$userData$db_trigger()
    
    out <- NULL
    tryCatch({
      # Join tables to get output needed
      out <- dbGetQuery(conn, "
SELECT 
  uuid,
	risk_ID,
	risks.name, 
	processes.name AS 'process',	
	prob_rating,
	severity_rating,
	rag_rating,	
	loss,
	description,
	firms.name AS 'firm', 
	departments.name AS 'department',
	created_at, 
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
           created_at = as.POSIXct(created_at, tz = "UTC"),
           modified_at = as.POSIXct(modified_at, tz = "UTC")
         ) %>%
         # find the most recently modified row for each risk
         group_by(risk_ID) %>%
         filter(modified_at == max(modified_at)) %>%
         ungroup() %>%
         # filter out deleted rows
         filter(is_deleted == 0) %>%
         arrange(name)
      
    }, error = function(err) {
      
      print(err)
      showToast("error", "Database Connection Error")
      
    })
    
    out
  })
  
  
  risks_table_prep <- reactiveVal(NULL)
  
  observeEvent(risks(), {
    out <- risks()
    
    # filter out unwanted columns
    out <- out %>% 
      select(risk_ID, name, process,
             prob_rating, severity_rating, rag_rating,
             loss, description,
             firm, department)
    
    #Create action buttons
    ids <- out$risk_ID
    actions <- purrr::map_chr(ids, function(risk_ID) {
      paste0(
        '<div class="btn-group" style="width: 75px;" role="group" aria-label="Basic example">
          <button class="btn btn-primary btn-sm edit_btn" data-toggle="tooltip" data-placement="top" title="Edit" id = ', risk_ID, ' style="margin: 0"><i class="fa fa-pencil-square-o"></i></button>
          <button class="btn btn-danger btn-sm delete_btn" data-toggle="tooltip" data-placement="top" title="Delete" id = ', risk_ID, ' style="margin: 0"><i class="fa fa-trash-o"></i></button>
        </div>'
      )
    })
    
    # Set the Action Buttons row to the first column of the `risks` table
    out <- cbind(
      tibble(" " = actions),
      out
    )
    
    if (is.null(risks_table_prep())) {
      # loading data into the table for the first time, so we render the entire table
      # rather than using a DT proxy
      risks_table_prep(out)
      
    } else {
      
      # manually hide the tooltip from the row so that it doesn't get stuck
      # when the row is deleted
      shinyjs::runjs("$('.btn-sm').tooltip('hide')")
      # table has already rendered, so use DT proxy to update the data in the
      # table without rerendering the entire table
      replaceData(risks_table_proxy, out, resetPaging = FALSE, rownames = FALSE)
      
    }
  })
  
  output$risks_table <- renderDT({
    req(risks_table_prep())
    out <- risks_table_prep()
    
    datatable(
      out,
      rownames = FALSE,
      colnames = c('ID', 'Name', 'Process', 'Probability', 'Severity', 'RAG', 
                   'Is Loss', 'Description', 'Firm', 'Department'),
      selection = "none",
      class = "compact stripe row-border nowrap",
      # Escape the HTML in all except 1st column (which has the buttons)
      escape = -1,
      extensions = c("Buttons"),
      options = list(
        scrollX = TRUE,
        dom = 'Bftip',
        buttons = list(
          list(
            extend = "excel",
            text = "Download",
            title = paste0("risks-", Sys.Date()),
            exportOptions = list(
              columns = 1:(length(out) - 1)
            )
          )
        ),
        columnDefs = list(
          list(targets = 0, orderable = FALSE)
        )
      )
    )
    
  })
  
  risks_table_proxy <- DT::dataTableProxy('risks_table')
  
  callModule(
    risk_edit_module,
    "add_risk",
    modal_title = "Add Risk",
    risk_to_edit = function() NULL,
    risk_IDs = unique(risks()$risk_ID),
    modal_trigger = reactive({input$add_risk})
  )

  risk_to_edit <- eventReactive(input$risk_id_to_edit, {
    risks() %>%
      filter(risk_ID == input$risk_id_to_edit)
  })
  
  callModule(
    risk_edit_module,
    "edit_risk",
    modal_title = "Edit Risk",
    risk_to_edit = risk_to_edit,
    risk_IDs = unique(risks()$risk_ID),
    modal_trigger = reactive({input$risk_id_to_edit})
  )

  risk_to_delete <- eventReactive(input$risk_id_to_delete, {
    risks() %>%
      filter(risk_ID == input$risk_id_to_delete) %>%
      as.list()
  })

  callModule(
    risk_delete_module,
    "delete_risk",
    modal_title = "Delete Risk",
    risk_to_delete = risk_to_delete,
    modal_trigger = reactive({input$risk_id_to_delete})
  )
  
}
