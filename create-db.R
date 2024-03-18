library(DBI)

con <- dbConnect(RSQLite::SQLite(), "econo-alerts-db.sqlite")

q <- "CREATE TABLE articles (
  Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  media TEXT,
  headline TEXT,
  url TEXT PRIMARY KEY,
  sent INTEGER DEFAULT 0
)"

dbExecute(con, q)

dbDisconnect(con)
