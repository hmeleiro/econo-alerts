suppressWarnings(suppressMessages({
library(dplyr)
library(rvest)
library(httr)
library(DBI)
}))

HOMEPAGE <- "https://www.publico.es/economia"
N_HEADLINES <- 1

source("functions.R", encoding = "UTF-8")

resp <- GET(HOMEPAGE)

if(resp$status_code == 200) {
  html <- resp %>% 
    read_html()
  
  articles <- html %>% html_elements(".listing-item")
  
  headlines <- articles %>% html_text(trim = T)
  urls <- articles %>% html_elements(".page-link") %>% html_attr("href")
  urls <- paste0("https://www.publico.es", urls)
  
  out <- tibble(headline = headlines[1:N_HEADLINES], url = urls[1:N_HEADLINES])
}


write2db(out, "Público")
