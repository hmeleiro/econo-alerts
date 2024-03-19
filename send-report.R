library(DBI)
library(dplyr)
library(httr)

API_TOKEN <- Sys.getenv("API_TOKEN")
CHAT_ID <- Sys.getenv("CHAT_ID")

source("functions.R", encoding = "UTF-8")

con <- dbConnect(RSQLite::SQLite(), "econo-alerts-db.sqlite")

q <- "SELECT * FROM articles WHERE sent = 0;"
articles <- dbGetQuery(con, q) %>% 
  mutate(
    headline = gsub("\n", "", headline),
    headline = trimws(headline)
  )

if(nrow(articles) > 0) {
  
  spain <- 
    articles %>% 
    filter(article_type == "news" & !grepl("Madrid", media) & media != "Financial Times")
  
  international <- 
    articles %>% 
    filter(article_type == "news" & media == "Financial Times")
  
  opinion <- 
    articles %>% 
    filter(article_type == "Opinión")
  
  madrid <- 
    articles %>% 
    filter(article_type == "news" & grepl("Madrid", media))
  
  
  msg_spain <- 
    purrr::map_chr(1:nrow(spain), function(i) {
      headline <- spain[i,]$headline
      url <- spain[i,]$url
      media <- spain[i,]$media
      sprintf("%s\n%s", headline, url)
      
    }) %>% 
    paste(collapse = "\n\n") %>% 
    paste0("<b>Nacional</b>\n\n", .)
  
  msg_international <- 
    purrr::map_chr(1:nrow(international), function(i) {
      headline <- international[i,]$headline
      url <- international[i,]$url
      media <- international[i,]$media
      sprintf("%s\n%s", headline, url)
      
    }) %>% 
    paste(collapse = "\n\n") %>% 
    paste0("<b>Internacional</b>\n\n", .)
  
  msg_opinion <- 
    purrr::map_chr(1:nrow(opinion), function(i) {
      headline <- opinion[i,]$headline
      url <- opinion[i,]$url
      media <- opinion[i,]$media
      sprintf("%s\n%s", headline, url)
      
    }) %>% 
    paste(collapse = "\n\n") %>% 
    paste0("<b>Opinión</b>\n\n", .)
  
  msg_madrid <- 
    purrr::map_chr(1:nrow(madrid), function(i) {
      headline <- madrid[i,]$headline
      url <- madrid[i,]$url
      media <- gsub(" \\(Madrid\\)", "", madrid[i,]$media)
      sprintf("%s\n%s", headline, url)
      
    }) %>% 
    paste(collapse = "\n\n") %>% 
    paste0("<b>Madrid</b>\n\n", .)
  
  title <- paste("🗞💸 Resumen prensa económica", format(Sys.Date(), "%d-%m-%Y"))
  msg <- paste(title, msg_spain, msg_international, msg_opinion, msg_madrid, sep = "\n\n")
  
  if(nchar(msg) > 4096) {
    msg1 <- paste(title, msg_spain, sep = "\n\n")
    msg2 <- paste0("\n\n", msg_international, "\n\n")
    msg3 <- paste(msg_opinion, msg_madrid, sep = "\n\n")

    sendMessage(msg1, API_TOKEN, CHAT_ID)
    Sys.sleep(.5)
    sendMessage(msg2, API_TOKEN, CHAT_ID)
    Sys.sleep(.5)
    sendMessage(msg3, API_TOKEN, CHAT_ID)
  } else {
    sendMessage(msg, API_TOKEN, CHAT_ID)
  }

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
