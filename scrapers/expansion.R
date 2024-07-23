suppressWarnings(suppressMessages({
  library(dplyr)
  library(rvest)
  library(httr)
  library(DBI)
}))


HOMEPAGE <- "https://www.expansion.com/"
N_HEADLINES <- 1

source("functions.R", encoding = "UTF-8")

resp <- GET(HOMEPAGE)

if (resp$status_code == 200) {
  html <- resp %>%
    read_html()

  main <- html %>% html_elements("main")

  h2 <- main %>% html_elements("header")
  headlines <- h2 %>% html_text()
  urls <- h2 %>%
    html_elements("a") %>%
    html_attr("href")

  out <- tibble(headline = headlines[1:N_HEADLINES], url = urls[1:N_HEADLINES])
}

write2db(out, "Expansión")
