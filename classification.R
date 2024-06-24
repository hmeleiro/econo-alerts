suppressWarnings(suppressMessages({
  library(dplyr)
  library(DBI)
  library(httr)
  library(stringr)
  library(reticulate)
  library(purrr)
}))

reticulate::py_config()
reticulate::py_available()

API_TOKEN <- Sys.getenv("API_TOKEN")
CHAT_ID <- Sys.getenv("CHAT_ID")

source("functions.R", encoding = "UTF-8")

con <- dbConnect(RSQLite::SQLite(), "econo-alerts-db.sqlite")

q <- "SELECT * FROM articles WHERE article_type = 'Opinión';"
articles <- dbGetQuery(con, q) %>% 
  mutate(
    headline = gsub("\n", "", headline),
    headline = trimws(headline)
  ) 



library(rvest)
library(httr)
url <- articles$url[1]

scrap_text <- function(url) {
  resp <- GET(url)
if(resp$status_code == 200) {
  text <- resp %>% read_html() %>% html_elements("p") %>% html_text() %>% paste(collapse = " ")
  return(text)
} else {
  return(NA)
  }
}


articles <- 
articles %>% 
mutate(text = map_chr(url, scrap_text)) %>%
filter(!is.na(text))


# Importing 🤗 transformers into R session
transformers <- reticulate::import("transformers")
# Instantiate a pipeline
model <- "valhalla/distilbart-mnli-12-3"
model <- "MoritzLaurer/mDeBERTa-v3-base-mnli-xnli"
classifier <- transformers$pipeline(task = "zero-shot-classification", model=model)



candidate_labels = c('economia', 'politica', 'internacional')
system.time(
    outputs <- classifier(substr(articles$headline[4:5], 1, 500), candidate_labels, multi_label = TRUE)
    )


# tibble(
#   headline = outputs$sequence,
#   labels = outputs$labels,
#   scores = outputs$scores
# ) %>% 
# filter(scores > 0.5) 

x <- articles[4:5,] %>% 
mutate(
    outputs = outputs
) %>% 
unnest(cols = outputs) %>% 
glimpse()


