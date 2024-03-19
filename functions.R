
write2db <- function(out, media, article_type = "news") {
  con <- dbConnect(RSQLite::SQLite(), "econo-alerts-db.sqlite")
  
  tryCatch({
    values <- 
      purrr::map2_chr(out$headline, out$url, function(headline, url) {
        sprintf('(\"%s\", \"%s\", \"%s\", \"%s\")', media, article_type, gsub('\"', "'", headline), url)
      }) %>% 
      paste(collapse = ", ")
    
    q <- sprintf("INSERT OR IGNORE INTO articles (media, article_type, headline, url) VALUES %s", values)
    
    
    dbExecute(con, q)
  }, finally = dbDisconnect(con))
  
  
}

sendMessage <- function(msg, API_TOKEN, CHAT_ID, encode = "json") {
  url <- sprintf("https://api.telegram.org/bot%s/sendMessage", URLencode(API_TOKEN))
  payload <- list(text = msg, parse_mode = "HTML", 
                  disable_web_page_preview = TRUE, disable_web_page_preview = TRUE, 
                  chat_id = CHAT_ID)
  POST(url, body = payload, content_type("application/json"), accept("application/json"), encode = encode)
}

