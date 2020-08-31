
risk_edit_module <- function(input, output, session, modal_title, risk_to_edit, risk_IDs, modal_trigger) {
  ns <- session$ns
  
  observeEvent(modal_trigger(), {
    hold <- risk_to_edit()

    # Get processes for selectInput control
    process_list <- NULL
    tryCatch({
      process_list <- dbGetQuery(conn, "SELECT * FROM processes;")
    }, error = function(err) {
      print(err)
      showToast("error", "Database Connection Error")
    })
  
    # Get firms for selectInput control
    firm_list <- NULL
    tryCatch({
      firm_list <- dbGetQuery(conn, "SELECT * FROM firms;")
    }, error = function(err) {
      print(err)
      showToast("error", "Database Connection Error")
    })
    
    # Get department for selectInput control
    department_list <- NULL
    tryCatch({
      department_list <- dbGetQuery(conn, "SELECT * FROM departments;")
    }, error = function(err) {
      print(err)
      showToast("error", "Database Connection Error")
    })
    
    showModal(
      modalDialog(
        
        fluidRow(
          column(
            width = 6,
            textInput(
              ns("risk_ID"),
              'Risk ID',
              value = ifelse(is.null(hold), "", hold$risk_ID),
              width = '100%'
            )
          ),
          column(
            width = 6,
            checkboxInput(
              ns('loss'),
              'Loss',
              value = ifelse(is.null(hold), FALSE, hold$loss)
            )
          )
        ),
        

        fluidRow(
          column(
            width = 12,
            textInput(
              ns("name"),
              'Name',
              value = ifelse(is.null(hold), "", hold$name),
              width = '100%'
            )
          )
        ),
        
        fluidRow(
          column(
            width = 12,
            textInput(
              ns("description"),
              'Description',
              value = ifelse(is.null(hold), "", hold$description),
              width = '100%'
            )
          )
        ),
        
        fluidRow(
          column(
            width = 6,
            numericInput(
              ns('prob_rating'),
              paste0('Probability Rating (1 to ', max_rating_prob, ')'),
              value = ifelse(is.null(hold), "", hold$prob_rating),
              min = 1,
              max = max_rating_prob,
              step = 1
            ),
            numericInput(
              ns('severity_rating'),
              'Severity Rating',
              value = ifelse(is.null(hold), "", hold$severity_rating),
              min = 1,
              max = 5,
              step = 1
            ),
            selectInput(
              ns('rag_rating'),
              'RAG Rating',
              choices = rag_options,
              selected = ifelse(is.null(hold), "", hold$rag_rating)
            )
          ),
          
          column(
            width = 6,
            selectInput(
              ns('process'),
              'Process',
              choices = process_list$name,
              selected = ifelse(is.null(hold), "", hold$process)
            ),
            selectInput(
              ns('firm'),
              'Firm',
              choices = firm_list$name,
              selected = ifelse(is.null(hold), "", hold$firm)
            ),
            selectInput(
              ns('department'),
              'Departments',
              choices = department_list$name,
              selected = ifelse(is.null(hold), "", hold$department)
            )
          )
     
        ),
        title = modal_title,
        size = 'm',
        footer = list(
          modalButton('Cancel'),
          actionButton(
            ns('submit'),
            'Submit',
            class = "btn btn-primary",
            style = "color: white"
          )
        )
      )
    )
    
    # Observe event for "Risk_ID" text input in Add/Edit Risk
    #  Cannot be same as another
    observeEvent(input$risk_ID, {
      
      # Cannot repeat a risk_ID
      prohibited_IDs <- risk_IDs
      if(modal_title=="Edit Risk"){
        # If editing a risk, can't change risk ID to that of another risk
        prohibited_IDs <- prohibited_IDs[-match(hold$risk_ID, prohibited_IDs)]
      } 
      
      if (trimws(input$risk_ID) %in% prohibited_IDs) {
        shinyFeedback::showFeedbackDanger(
          "risk_ID",
          text = "Cannot use an existing Risk ID.  Please choose another!"
        )
        shinyjs::disable('submit')
      } else {
        shinyFeedback::hideFeedback("risk_ID")
        shinyjs::enable('submit')
      }
      
    })
    
    
    # Observe event for "Name" text input in Add/Edit Risk
    observeEvent(input$name, {
      
      if (input$name == "") {
         shinyFeedback::showFeedbackDanger(
           "name",
           text = "Must enter a risk name!"
         )
         shinyjs::disable('submit')
       } else {
         shinyFeedback::hideFeedback("name")
         shinyjs::enable('submit')
       }
    })
    
    # Observe event for "prob_rating" input in Add/Edit Risk
    observeEvent(input$prob_rating, {
      req(input$prob_rating)
      
      if((input$prob_rating < 1) || (input$prob_rating > max_rating_prob)) {
        shinyFeedback::showFeedbackDanger(
          "prob_rating",
          text = "Ensure probability rating is within bounds."
        )
        shinyjs::disable('submit')
        
      } else if (input$prob_rating %% 1 > 0) {
        shinyFeedback::showFeedbackDanger(
          "prob_rating",
          text = "Rating must be an integer."
        )
        shinyjs::disable('submit')
        
      } else {
        shinyFeedback::hideFeedback("prob_rating")
        shinyjs::enable('submit')
      }
      
    })

    # Observe event for "severity_rating" input in Add/Edit Risk
    observeEvent(input$severity_rating, {
      req(input$severity_rating)
      
      if((input$severity_rating < 1) || (input$severity_rating > max_rating_severity)) {
        shinyFeedback::showFeedbackDanger(
          "severity_rating",
          text = "Ensure severity rating is within bounds."
        )
      } else if (input$severity_rating %% 1 > 0) {
        shinyFeedback::showFeedbackDanger(
          "severity_rating",
          text = "Rating must be an integer."
        )
        shinyjs::disable('submit')
        
      } else {
        shinyFeedback::hideFeedback("severity_rating")
        shinyjs::enable('submit')
      }
      
    })
    
  })
  
  
  
  edit_risk_dat <- reactive({
    hold <- risk_to_edit()
 
    processes <- dbGetQuery(conn, "SELECT * FROM processes")
    firms <- dbGetQuery(conn, "SELECT * FROM firms")
    departments <- dbGetQuery(conn, "SELECT * FROM departments")
    
    out <- list(
      "uuid" = if (is.null(hold)) uuid::UUIDgenerate() else hold$uuid,
      "risk_ID" = input$risk_ID,
       "name" = input$name,
       "loss" = input$loss,
       "firm_ID" = firms[firms$name==input$firm, "firm_ID"],
       "department_ID" = departments[departments$name==input$department, "department_ID"],
       "process_ID" = processes[processes$name==input$process, "process_ID"],
       "description" = input$description,
       "prob_rating" = input$prob_rating,
       "severity_rating" = input$severity_rating,
       "rag_rating" = input$rag_rating
    )
    
    time_now <- as.character(lubridate::with_tz(Sys.time(), tzone = "UTC"))

    if (is.null(hold)) {
      # adding a new risk

      out$created_at <- time_now
      out$created_by <- session$userData$email
    } else {
      # Editing existing risk

      out$created_at <- as.character(hold$created_at)
      out$created_by <- if (is.null(hold$created_by)) "" else hold$created_by  #Only necessary because I didn't establish the database with data properly and this field was missing!
    }

    out$modified_at <- time_now
    out$modified_by <- session$userData$email

    out$is_deleted <- FALSE
    
    out
  })
  
  validate_edit <- eventReactive(input$submit, {
    dat <- edit_risk_dat()
    
    # Logic to validate inputs...
    
    dat
  })
  
  observeEvent(validate_edit(), {
    removeModal()
    dat <- validate_edit()

    tryCatch({
      
      # creating a new risk
      dat$uuid <- uuid::UUIDgenerate()

      dbExecute(
         conn,
         "INSERT INTO risks (uuid, risk_ID, name, loss, firm_ID, department_ID, process_ID,
         description, prob_rating, severity_rating, rag_rating, created_at, created_by,
         modified_at, modified_by, is_deleted) VALUES
         (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
         params = unname(dat)
      )

      session$userData$db_trigger(session$userData$db_trigger() + 1)
      showToast("success", paste0(modal_title, " Success"))
    }, error = function(error) {
      
      showToast("error", paste0(modal_title, " Error"))
      
      print(error)
    })
  })
  
}