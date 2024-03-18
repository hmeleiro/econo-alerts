library(DBI)
library(dplyr)
library(httr)

API_TOKEN <- Sys.getenv("API_TOKEN")
CHAT_ID <- Sys.getenv("CHAT_ID")

source("functions.R", encoding = "UTF-8")

con <- dbConnect(RSQLite::SQLite(), "econo-alerts-db.sqlite")

q <- "SELECT * FROM articles WHERE sent = 0;"
articles <- dbGetQuery(con, q)

if(nrow(articles) > 0) {
  
  msg <- 
    purrr::map_chr(1:nrow(articles), function(i) {
      headline <- articles[i,]$headline
      url <- articles[i,]$url
      media <- articles[i,]$media
      sprintf("[%s](%s) (%s)", headline, url, media)
      
    }) %>% 
    paste(collapse = "\n\n")

  
  resp <- sendMessage(msg, API_TOKEN, CHAT_ID)
  
  if(resp$status_code == 200) {
    urls_sent <- 
      purrr::map_chr(unique(articles$url), function(x) {
        sprintf("'%s'", x)
      }) %>% 
      paste0(collapse = ", ")
    
    q <- sprintf("UPDATE articles SET sent = 1 WHERE url IN (%s);", urls_sent) 
    x <- dbExecute(con, q)
  }
  
}
