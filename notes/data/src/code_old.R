library(stringi)
library(readr)

x <- read_csv("../foods.csv")
wiki <- stri_replace_all(stri_trans_tolower(x$item), "_", fixed = " ")

wiki <-
c("apple", "asparagus", "avocado", "banana", "chickpea",
"green_bean", "beef", "bell_pepper", "callinectes_sapidus", "broccoli",
"cabbage", "cantaloupe", "carrot", "catfish", "cauliflower",
"celery", "cheese", "chicken", "clam", "cod", "maize",
"cucumber", "duck", "flounder", "grapefruit", "grape",
"halibut", "haddock", "kiwifruit", "sheep", "lemon", "lettuce",
"lime", "lobster", "milk", "mushroom", "oat",
"onion", "orange_(fruit)", "oyster", "peach", "pear", "penne", "pineapple",
"plum", "pork", "quinoa", "brown_rice", "salmon", "scallop",
"shrimp", "sour_cream", "strawberry", "sweet_potato", "swordfish",
"tangerine", "tomato", "tuna", "turkey", "potato", "yogurt"
)

for (i in seq_along(wiki))
{
  input <- sprintf("https://en.wikipedia.org/w/api.php?action=parse&format=json&page=%s", wiki[i])
  output <- sprintf("%s.json", wiki[i])

  x <- readLines(input)
  writeLines(x, output)
}
