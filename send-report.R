library(DBI)

API_TOKEN <- Sys.getenv("API_TOKEN")
CHAT_ID <- Sys.getenv("CHAT_ID")

con <- dbConnect(RSQLite::SQLite(), "econo-alerts-db.sqlite")

q <- "SELECT * FROM articles WHERE sent = 0;"
articles <- dbGetQuery(con, q)

msg <- 
  purrr::map_chr(1:nrow(articles), function(i) {
  headline <- articles[i,]$headline
  url <- articles[i,]$url
  media <- articles[i,]$media
  sprintf("[%s](%s) (%s)", headline, url, media)
  
}) %>% 
  paste(collapse = "\n\n")

sendMessage(msg, API_TOKEN, CHAT_ID)
