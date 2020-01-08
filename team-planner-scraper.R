# Install RStudio and import this script. 
# Have an Excel named ids with a single column named Id and a list of id's to scrape in the same directory
# Replace loop lengths in this file and run the script. It takes about 65 seconds per ID. Can be left running in the background.

# Libraries to import. Make sure you import their dependencies also
if (!require(remotes)) {
  install.packages("remotes") 
}

remotes::install_github("wiscostret/fplscrapR")

library(tidyverse)
library(RSelenium)
library(rvest)
library(XML)
library(jsonlite)
library(readxl)
library(fplscrapR)
library(haven)

# Excel file with a list of team id's to request for in a column headered "Id"
id <- read_excel("ids.xlsx")

# Connecting to server
# Must have firefox installed
shell('docker run -d -p 4445:4444 selenium/standalone-firefox')
remDr <- remoteDriver(remoteServerAddr = "localhost", port = 4445L, browserName = "firefox'")
remDr$open()
remDr$navigate("https://fplreview.com/team-planner/")

data <- list()

# For each ID i in your list of id's
for (i in 1:6) {
  # Find the ID input box element
  webElem <- remDr$findElement(using = "name", value = "teamID")
  # Paste the ID i into the box
  webElem$sendKeysToElement(list(paste(ids$Id[i])))
  # Find the Search button
  webElem2 <- remDr$findElement(using = "css", ".article-body-inner > form:nth-child(2) > input:nth-child(6)")
  # Press enter on it
  webElem2$sendKeysToElement(list("R Cran", key = "enter"))
  
  # Sleep
  testit(65)
  
  # Get the html source of the returned html
  temp_html <- remDr$getPageSource()
  temp_html <- temp_html[[1]] %>% read_html
  
  # Store data
  temp_table <- data.frame(temp_html %>% html_nodes(xpath=paste('//*[@id="forecast_table"]')) %>% html_table())
  
  data[[i]] <- temp_table
}

# Close resources
remDr$close()
rD$server$stop()

# Extra code to gather the data in a clean format which you can paste into excel

# Define a frame to put the data into, I've get it as output
output <- data.frame(matrix(ncol=7,nrow=21))
# Define the column names
colnames(output) <- c("Id","gw1","gw2","gw3","gw4","gw5","Total")
# For each ID, set the stored data
for (i in 1:6) {
  output$Id[i] <- id$Id[i]
  output$gw1[i] <- data[[i]][[1]][1]
  output$gw2[i] <- data[[i]][[2]][1]
  output$gw3[i] <- data[[i]][[3]][1]
  output$gw4[i] <- data[[i]][[4]][1]
  output$gw5[i] <- data[[i]][[5]][1]
  output$total[i] <- data[[i]][[6]][1]
}
# Sort?
output <- data.frame(sapply(output, as.numeric))

# Sleeps to allow the request to go through
testit <- function(x) {
  p1 <- proc.time()
  Sys.sleep(x)
  proc.time() - p1 # The cpu usage should be negligible
}

