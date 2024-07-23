suppressWarnings(suppressMessages({
  library(dplyr)
  library(rvest)
  library(httr)
  library(DBI)
}))


HOMEPAGE <- "https://cincodias.elpais.com/"
N_HEADLINES <- 3

source("functions.R", encoding = "UTF-8")

resp <- GET(HOMEPAGE)

if (resp$status_code == 200) {
  html <- resp %>%
    read_html()

  h2 <- html %>% html_elements("h2")
  headlines <- h2 %>% html_text()
  urls <- h2 %>%
    html_elements("a") %>%
    html_attr("href")

  headlines <- headlines[!grepl("https://elpais.com", urls)]
  urls <- urls[!grepl("https://elpais.com", urls)]

  out <- tibble(headline = headlines[1:N_HEADLINES], url = urls[1:N_HEADLINES])
}

write2db(out, "Cinco Días")
