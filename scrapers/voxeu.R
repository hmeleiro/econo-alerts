suppressWarnings(suppressMessages({
  library(dplyr)
  library(rvest)
  library(httr)
  library(DBI)
}))


HOMEPAGE <- "https://cepr.org/voxeu"
N_HEADLINES <- 1

source("functions.R", encoding = "UTF-8")


resp <- GET(HOMEPAGE)

if(resp$status_code == 200) {
  html <- resp %>% 
    read_html()
  
  articles <- html %>% html_elements("article") 
  
  headlines <- articles %>% html_elements(".c-card__title") %>% 
    html_elements("a") %>% html_text(trim = T)
  urls <- articles %>% html_elements(".c-card__title") %>% 
    html_elements("a") %>% html_attr("href")
  urls <- paste0("https://cepr.org", urls)
  
  out <- tibble(headline = headlines[1:N_HEADLINES], url = urls[1:N_HEADLINES])
}

write2db(out, media = "VoxEU", article_type = "Opinión")
