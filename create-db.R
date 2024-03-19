library(DBI)

con <- dbConnect(RSQLite::SQLite(), "econo-alerts-db.sqlite")

q <- "CREATE TABLE articles (
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  media TEXT,
  article_type TEXT,
  headline TEXT,
  url TEXT PRIMARY KEY,
  sent INTEGER DEFAULT 0
)"

dbExecute(con, q)

dbDisconnect(con)
