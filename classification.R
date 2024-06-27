suppressWarnings(suppressMessages({
  library(dplyr)
  library(DBI)
  library(httr)
  library(rvest)
  library(stringr)
  library(reticulate)
  library(purrr)
  library(tidyr)
}))

scrap_text <- function(url) {
  resp <- GET(url)
  if (resp$status_code == 200) {
    text <- resp %>%
      read_html() %>%
      html_elements("p") %>%
      html_text() %>%
      paste(collapse = " ")
    return(text)
  } else {
    return(NA)
  }
}

first_n_words <- function(text, n = 100) {
  words <- strsplit(text, " ")[[1]]
  words <- words[words != ""]
  return(paste(words[1:n], collapse = " "))
}

reticulate::py_config()
reticulate::py_available()

source("functions.R", encoding = "UTF-8")

con <- dbConnect(RSQLite::SQLite(), "econo-alerts-db.sqlite")
q <- "SELECT * FROM articles WHERE article_type = 'Opinión' AND DATE(timestamp) = DATE('now') AND tagged = 0;"
articles <- dbGetQuery(con, q) %>%
  mutate(
    headline = gsub("\n", "", headline),
    headline = trimws(headline)
  ) %>%
  filter(media != "Financial Times") %>%
  select(-c(economia, internacional, politica))
dbDisconnect(con)

# Scraping text from URL
articles <-
  articles %>%
  # slice_sample(n = 5) %>%
  mutate(
    text = map_chr(url, scrap_text),
    first_n_words = map_chr(text, first_n_words, n = 200)
  ) %>%
  filter(!is.na(text))


if (nrow(articles) > 0) {
  # # Importing 🤗 transformers into R session
  transformers <- reticulate::import("transformers")
  # # Instantiate a pipeline
  # model <- "valhalla/distilbart-mnli-12-3"
  # model <- "MoritzLaurer/mDeBERTa-v3-base-mnli-xnli"
  model <- "MoritzLaurer/multilingual-MiniLMv2-L6-mnli-xnli"
  classifier <- transformers$pipeline(task = "zero-shot-classification", model = model)


  candidate_labels <- c("economia", "politica", "internacional")
  system.time(
    outputs <- classifier(articles$first_n_words, candidate_labels, multi_label = TRUE)
  )


  outputs <- outputs %>%
    map_df(as_tibble) %>%
    rename(first_n_words = sequence)


  articles_with_classes <- articles %>%
    left_join(outputs) %>%
    pivot_wider(names_from = "labels", values_from = "scores")


  i <- 1

  for (i in 1:nrow(articles_with_classes)) {
    tmp <- articles_with_classes[i, ]
    url <- tmp$url
    economia <- round(tmp$economia, 4)
    politica <- round(tmp$politica, 4)
    internacional <- round(tmp$internacional, 4)

    con <- dbConnect(RSQLite::SQLite(), "econo-alerts-db.sqlite")
    tryCatch(
      {
        q <- sprintf(
          "UPDATE articles SET economia = %s, politica = %s, internacional = %s, tagged = 1 where url = '%s'",
          economia, politica, internacional, url
        )
        dbExecute(con, q)
      },
      finally = dbDisconnect(con)
    )
  }
}
