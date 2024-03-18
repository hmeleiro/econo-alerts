library(dplyr)
library(rvest)
library(httr)
library(DBI)

HOMEPAGE <- "https://www.elmundo.es/economia.html"
N_HEADLINES <- 2

source("functions.R", encoding = "UTF-8")

resp <- GET(HOMEPAGE)

if(resp$status_code == 200) {
  html <- resp %>% 
    read_html()
  
  articles <- html %>% html_elements("header")
  
  headlines <- articles %>% html_elements("h2") %>% html_text(trim = T)
  urls <- articles %>% html_elements("a") %>% html_attr("href")
  
  out <- tibble(headline = headlines[1:N_HEADLINES], url = urls[1:N_HEADLINES])
}

write2db(out, "El Mundo")
