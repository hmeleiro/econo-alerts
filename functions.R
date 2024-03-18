
write2db <- function(out, media) {
  con <- dbConnect(RSQLite::SQLite(), "econo-alerts-db.sqlite")
  
  tryCatch({
    values <- 
      purrr::map2_chr(out$headline, out$url, function(headline, url) {
        sprintf("('%s', '%s', '%s')", media, headline, url)
      }) %>% 
      paste(collapse = ", ")
    
    q <- sprintf("INSERT OR IGNORE INTO articles (media, headline, url) VALUES %s", values)
    
    
    dbExecute(con, q)
  }, finally = dbDisconnect(con))
  
  
}

sendMessage <- function(msg, API_TOKEN, CHAT_ID, encode = "json") {
  url <- sprintf("https://api.telegram.org/bot%s/sendMessage", URLencode(API_TOKEN))
  payload <- list(text = msg, parse_mode = "Markdown", disable_web_page_preview = TRUE, chat_id = CHAT_ID)
  POST(url, body = payload, content_type("application/json"), accept("application/json"), encode = encode)
}

