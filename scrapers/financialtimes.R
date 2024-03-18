suppressWarnings(suppressMessages({
library(dplyr)
library(rvest)
library(httr)
library(DBI)
}))


HOMEPAGE <- "https://www.ft.com/"
N_HEADLINES <- 2

source("functions.R", encoding = "UTF-8")

resp <- GET(HOMEPAGE)

if(resp$status_code == 200) {
  html <- resp %>% 
    read_html()
  
  primary_stories <- html %>% html_elements(".featured-story-content,.primary-story__teaser")
  primary_stories <- primary_stories[1:N_HEADLINES]%>% html_elements(".headline")
  
  headlines <- primary_stories %>% html_text()
  urls <- primary_stories %>% html_elements("a") %>% html_attr("href")
  urls <- paste0("https://www.ft.com", urls)
  
  out <- tibble(headline = headlines[1:N_HEADLINES], url = urls[1:N_HEADLINES])
}

write2db(out, "Financial Times")
