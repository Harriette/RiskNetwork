
risk_delete_module <- function(input, output, session, modal_title, risk_to_delete, modal_trigger) {
  ns <- session$ns
  # Observes trigger for this module (here, the Delete Button)
  observeEvent(modal_trigger(), {

    # Authorize who is able to access particular buttons (here, modules)
    #******** DON'T LIKE FAILURE WITHOUT MESSAGE - SHOULD FIX ********************
    req(session$userData$email == 'myname@me.com')
  
    showModal(
      modalDialog(
        div(
          style = "padding: 30px;",
          class = "text-center",
          h2('Are you sure you want to delete the following risk?'),
          h2(paste0(
              risk_to_delete()$risk_ID,
              ": ",
              risk_to_delete()$name
            )
          )
        ),
        br(),
        title = modal_title,
        size = "m",
        footer = list(
          modalButton("Cancel"),
          actionButton(
            ns("delete_button"),
            "Delete Risk",
            class = "btn-danger",
            style = "color: #FFF;"
          )
        )
      )
    )
  })
  
  
  
  observeEvent(input$delete_button, {
    req(modal_trigger())
    
    removeModal()
    
    hold <- risk_to_delete()
    
    processes <- dbGetQuery(conn, "SELECT * FROM processes")
    firms <- dbGetQuery(conn, "SELECT * FROM firms")
    departments <- dbGetQuery(conn, "SELECT * FROM departments")
    
    out <- list(
      "uuid" = hold$uuid,
      "risk_ID" = hold$risk_ID,
      "name" = hold$name,
      "loss" = hold$loss,
      "firm_ID" = firms[firms$name==hold$firm, "firm_ID"],
      "department_ID" = departments[departments$name==hold$department, "department_ID"],
      "process_ID" = processes[processes$name==hold$process, "process_ID"],
      "description" = hold$description,
      "prob_rating" = hold$prob_rating,
      "severity_rating" = hold$severity_rating,
      "rag_rating" = hold$rag_rating
    )
    
    time_now <- as.character(lubridate::with_tz(Sys.time(), tzone = "UTC"))
    
    out$created_at <- as.character(lubridate::with_tz(hold$created_at, tzone = "UTC"))
    out$created_by <- if (is.null(hold$created_by)) "" else hold$created_by  #Only necessary because I didn't establish the database with data properly and this field was missing!
    out$modified_at <- time_now
    out$modified_by <- session$userData$email
    out$is_deleted <- 1
    

    
    tryCatch({
      
      # creating a new risk
      out$uuid <- uuid::UUIDgenerate()
      
      DBI::dbExecute(
        conn,
        "INSERT INTO risks (uuid, risk_ID, name, loss, firm_ID, department_ID, process_ID,
         description, prob_rating, severity_rating, rag_rating, created_at, created_by,
         modified_at, modified_by, is_deleted) VALUES
         (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        params = unname(out)
      )
      
      session$userData$db_trigger(session$userData$db_trigger() + 1)
      showToast("success", "Risk Successfully Deleted")
    }, error = function(error) {
      
      showToast("error", "Error Deleting Risk")
      
      print(error)
    })
  })
}