suppressWarnings(suppressMessages({
  library(dplyr)
  library(rvest)
  library(httr)
  library(DBI)
}))


HOMEPAGE <- "https://www.ft.com/ft-view"
N_HEADLINES <- 1

source("functions.R", encoding = "UTF-8")


get_headline <- function(url) {
  resp <- GET(url)
  if (resp$status_code == 200) {
    html <- resp %>%
      read_html()

    headline <- html %>%
      html_element("h1") %>%
      html_text()

    return(headline)
  } else {
    return(NA)
  }
}

resp <- GET(HOMEPAGE)

if (resp$status_code == 200) {
  html <- resp %>%
    read_html()

  urls <-
    html %>%
    html_elements("p") %>%
    html_elements("a") %>%
    html_attr("href") %>%
    gsub("\\\\\"", "", .)

  urls <- paste0("https://www.ft.com", urls[1:N_HEADLINES])
  headlines <- purrr::map_chr(urls, get_headline)

  out <- tibble(headline = headlines, url = urls)
}

write2db(out, media = "Financial Times", article_type = "Opinión")
