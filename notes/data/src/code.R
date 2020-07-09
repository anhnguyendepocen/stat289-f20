library(stringi)
library(readr)
library(jsonlite)
library(dplyr)
library(xml2)

x <- read_csv("../foods.csv")

# grab current wikipedia page
for (i in seq_along(x$wiki))
{
  input <- sprintf("https://en.wikipedia.org/w/api.php?action=parse&format=json&page=%s", x$wiki[i])
  output <- sprintf("wiki_parse/%s.json", x$wiki[i])

  lines <- readLines(input)
  writeLines(lines, output)
}

# grab page views
for (i in seq_along(x$wiki))
{
  input <- sprintf("https://en.wikipedia.org/w/api.php?action=query&format=json&prop=pageviews&titles=%s", x$wiki[i])
  output <- sprintf("wiki_pageviews/%s.json", x$wiki[i])

  lines <- readLines(input)
  writeLines(lines, output)
}

# grab revision history
for (i in seq_along(x$wiki))
{
  z <- read_json(sprintf("wiki_parse/%s.json", x$wiki[i]))

  input <- sprintf("https://en.wikipedia.org/w/api.php?action=query&format=json&prop=revisions&rvprop=ids|size|timestamp|comment|user&rvlimit=max&pageids=%d&rvstartid=%d&",
                 z$parse$pageid, z$parse$revid)
  output <- sprintf("wiki_history/%s.json", x$wiki[i])

  lines <- readLines(input)
  writeLines(lines, output)
}

# download images
for (i in seq_along(x$wiki))
{
  z <- read_json(sprintf("wiki_parse/%s.json", x$wiki[i]))
  text <- z$parse$text

  img_links <- stri_extract_all(text, regex="src=\"//upload.wikimedia.org/wikipedia/commons/[^ ]+ ")[[1]]
  img_links <- stri_sub(unique(img_links), 8, -3)
  img_links <- img_links[!stri_detect(img_links, fixed = ".svg")]
  img_links <- img_links[stri_sub(img_links, -4, -1) == ".jpg"]
  img_links <- sprintf("https://%s", img_links)
  img_output <- sprintf("wiki_images/%s", basename(img_links))

  for (j in seq_along(img_links))
  {
    download.file(img_links[j], img_output[j])
  }

}

# tidy page views
page_views <- NULL
for (i in seq_along(x$wiki))
{
  z <- read_json(sprintf("wiki_pageviews/%s.json", x$wiki[i]))
  pviews <- z$query$pages[[1]]$pageviews

  date <- names(pviews)
  page_views <- bind_rows(page_views, tibble(
    item = x$item[i],
    year = as.numeric(stri_sub(date, 1, 4)),
    month = as.numeric(stri_sub(date, 6, 7)),
    day = as.numeric(stri_sub(date, 9, 10)),
    views = as.numeric(pviews)
  ))
}
write_csv(page_views, "../page_views.csv")

# tidy revision history
page_revisions <- NULL
for (i in seq_along(x$wiki))
{
  z <- read_json(sprintf("wiki_history/%s.json", x$wiki[i]))
  revs <- z$query$pages[[1]]$revisions

  time <- sapply(revs, getElement, "timestamp")
  user <- sapply(revs, getElement, "user")
  size <- sapply(revs, getElement, "size")
  comment <- sapply(revs, function(v) {
    res <- getElement(v, "comment")
    if (length(res) == 0) res <- ""
    res
  })

  page_revisions <- bind_rows(page_revisions, tibble(
    item = x$item[i],
    year = as.numeric(stri_sub(time, 1, 4)),
    month = as.numeric(stri_sub(time, 6, 7)),
    day = as.numeric(stri_sub(time, 9, 10)),
    hour = as.numeric(stri_sub(time, 12, 13)),
    minute = as.numeric(stri_sub(time, 15, 16)),
    second = as.numeric(stri_sub(time, 18, 19)),
    user = user,
    page_size = size,
    comment = comment
  ))
}
write_csv(page_revisions, "../page_revisions.csv")

# tidy text data
page_text <- NULL
for (i in seq_along(x$wiki))
{
  z <- read_json(sprintf("wiki_parse/%s.json", x$wiki[i]))
  doc <- read_xml(z$parse$text[[1]])

  paragraphs <- sapply(xml_find_all(doc, ".//p"), xml_text)
  paragraphs <- stri_replace_all(paragraphs, "", regex = "\\[[0-9]+\\]")
  paragraphs <- stri_replace_all(paragraphs, "", fixed = "\n")
  paragraphs <- paragraphs[stri_length(paragraphs) > 100]
  paragraphs <- stri_paste(paragraphs, collapse = "\n")

  page_text <- bind_rows(page_text, tibble(
    item = x$item[i],
    page_text = paragraphs
  ))
}
write_csv(page_text, "../page_text.csv")
