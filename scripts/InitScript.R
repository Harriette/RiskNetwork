# Initialise connection

library(RMariaDB)
library(DBI)
library(config)

thispath <- "D:/Nigel/Dropbox/MyApps/RiskNetwork/"

dw <- config::get(file = paste0(thispath, 'app/config.yml'))

conn <- dbConnect(drv=dw$drv, 
                  user=dw$user, 
                  password=dw$password,
                  host=dw$host, 
                  port=dw$port,
                  dbname=dw$dbname)


# Initialise database

# May manually have to delete existing directory before re-initialising

initdb_sql <- paste(readLines(paste0(thispath, "scripts/initdb.sql")), collapse = "\n")

dbExecute(conn, initdb_sql)




# Data

# May manually have to delete existing directory before re-initialising

# Processes
t1 <- read.csv(paste0(thispath, 'scripts/Initial_Processes.csv'))

DBI::dbWriteTable(
  conn,
  name = "processes",
  value = t1,
  overwrite = FALSE,
  append = TRUE
)

# Risks
t1 <- read.csv(paste0(thispath, 'scripts/Initial_Risks.csv'))
t1$uuid <- uuid::UUIDgenerate(n=nrow(t1))
t1 <- t1[, c(ncol(t1), 1:(ncol(t1)-1))]

time_now <- as.character(lubridate::with_tz(Sys.time(), tzone = "UTC"))

t1$created_at <- time_now
t1$modified_at <- time_now

DBI::dbWriteTable(
  conn,
  name = "risks",
  value = t1,
  overwrite = FALSE,
  append = TRUE
)

# Risk links
t2 <- read.csv(paste0(thispath, 'scripts/Initial_RiskLinks.csv'))

t2 <- merge.data.frame(t2, t1[,1:2], by.x = 'riskfrom_ID', by.y = 'risk_ID')
t2 <- merge.data.frame(t2, t1[,1:2], by.x = 'riskto_ID', by.y = 'risk_ID')
t2 <- t2[ , c('risklink_ID', 'uuid.x', 'uuid.y')]
names(t2) <- c('risklink_ID', 'riskfrom_ID', 'riskto_ID')

DBI::dbWriteTable(
  conn,
  name = "risklinks",
  value = t2,
  overwrite = FALSE,
  append = TRUE
)



