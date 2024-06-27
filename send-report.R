suppressWarnings(suppressMessages({
  library(dplyr)
  library(DBI)
  library(httr)
  library(stringr)
}))


API_TOKEN <- Sys.getenv("API_TOKEN")
CHAT_ID <- Sys.getenv("CHAT_ID")

source("functions.R", encoding = "UTF-8")

con <- dbConnect(RSQLite::SQLite(), "econo-alerts-db.sqlite")

q <- "SELECT * FROM articles WHERE sent = 0;"
articles <- dbGetQuery(con, q) %>%
  mutate(
    headline = gsub("\n", "", headline),
    headline = trimws(headline)
  )

if (nrow(articles) > 0) {
  spain <-
    articles %>%
    filter(article_type == "news" & !grepl("Madrid", media) & media != "Financial Times")

  international <-
    articles %>%
    filter(article_type == "news" & media == "Financial Times")

  opinion <-
    articles %>%
    filter(article_type == "Opinión", economia >= .4)

  madrid <-
    articles %>%
    filter(article_type == "news" & grepl("Madrid", media))


  msg_spain <-
    purrr::map_chr(1:nrow(spain), function(i) {
      headline <- spain[i, ]$headline
      url <- spain[i, ]$url
      media <- spain[i, ]$media
      sprintf("%s\n%s", headline, url)
    }) %>%
    paste(collapse = "\n\n") %>%
    paste0("<b>Nacional</b>\n\n", .)

  msg_international <-
    purrr::map_chr(1:nrow(international), function(i) {
      headline <- international[i, ]$headline
      url <- international[i, ]$url
      media <- international[i, ]$media
      sprintf("%s\n%s", headline, url)
    }) %>%
    paste(collapse = "\n\n") %>%
    paste0("<b>Internacional</b>\n\n", .)

  msg_opinion <-
    purrr::map_chr(1:nrow(opinion), function(i) {
      headline <- opinion[i, ]$headline
      url <- opinion[i, ]$url
      media <- opinion[i, ]$media
      sprintf("%s\n%s", headline, url)
    }) %>%
    paste(collapse = "\n\n") %>%
    paste0("<b>Opinión</b>\n\n", .)

  msg_madrid <-
    purrr::map_chr(1:nrow(madrid), function(i) {
      headline <- madrid[i, ]$headline
      url <- madrid[i, ]$url
      media <- gsub(" \\(Madrid\\)", "", madrid[i, ]$media)
      sprintf("%s\n%s", headline, url)
    }) %>%
    paste(collapse = "\n\n") %>%
    paste0("<b>Madrid</b>\n\n", .)

  title <- paste("🗞💸 <b>Resumen prensa económica</b>", format(Sys.Date(), "%d-%m-%Y"))
  msg <- paste(title, msg_spain, msg_international, msg_opinion, msg_madrid, sep = "\n\n")

  if (nchar(msg) > 4096) {
    msg_list <- str_split(msg, "\n\n")[[1]]
    msg_short <- ""

    while (length(msg_list) > 0) {
      while (nchar(msg_short) < 4096 & length(msg_list) > 0) {
        if (nchar(msg_short) + nchar(msg_list[1]) > 4096) {
          break
        }
        msg_short <- paste0(msg_short, msg_list[1], "\n\n")
        msg_list <- msg_list[-1]
      }
      resp <- sendMessage(msg_short, API_TOKEN, CHAT_ID)
      if (resp$status_code != 200) {
        break
      }

      msg_short <- ""
      Sys.sleep(.5)
    }
  } else {
    resp <- sendMessage(msg, API_TOKEN, CHAT_ID)
  }

  if (resp$status_code == 200) {
    urls_sent <-
      purrr::map_chr(unique(articles$url), function(x) {
        sprintf("'%s'", x)
      }) %>%
      paste0(collapse = ", ")

    q <- sprintf("UPDATE articles SET sent = 1 WHERE url IN (%s);", urls_sent)
    x <- dbExecute(con, q)
  }
}
