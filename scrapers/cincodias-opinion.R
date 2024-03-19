suppressWarnings(suppressMessages({
  library(dplyr)
  library(rvest)
  library(httr)
  library(DBI)
}))


HOMEPAGE <- "https://cincodias.elpais.com/opinion/"
N_HEADLINES <- 2

source("functions.R", encoding = "UTF-8")

resp <- GET(HOMEPAGE)

if(resp$status_code == 200) {
  html <- resp %>% 
    read_html()
  
  main <- html %>% html_elements("main")
  
  articles <- main %>% html_elements("article")
  
  headlines <- articles %>% html_elements("h2") %>% html_text()
  urls <- articles %>% html_elements("a") %>% html_attr("href")
  headlines <- headlines[!grepl("https://elpais.com", urls)]
  urls <- urls[!grepl("https://elpais.com", urls)]
  
  out <- tibble(headline = headlines[1:N_HEADLINES], url = urls[1:N_HEADLINES])
}

write2db(out, media = "Cinco Días", article_type = "Opinión")
