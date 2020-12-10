library(dplyr)
library(shiny)
library(shinydashboard)
library(ggplot2)
library(plotly)
library(lubridate)
library(stringr)
library(tidyr)
library(DT)
library(shinydashboardPlus)

# Preprocessing overview
overview <- read.csv("data/county_overview.csv")
# overview 
#select * from ...
# where county = "Hawaii"

names(overview) <- c('County',
                     'Population',
                     'Area',
                     'Density',
                     'Flower',
                     'Color',
                     'Largest_Settlement',
                     'Description',
                     'Web')

overview$County = str_trim(overview$County)
mylist <- as.list(overview["County"])

description <- overview[1, "Description"]

covid <- read.csv("data/covid_by_county_in_hawaii.csv")
names(covid) <- c('Date',
                     'County',
                     'State',
                     'Federal_ID',
                     'Cumulative_Cases',
                     'Cumulative_Death')
covid$County = str_trim(covid$County)






#by phil------------------------------------------------
## Load Libraries


# database library
library(DBI)
library(odbc)
# data library
library(tidyverse)


## Connect Database


# check drivers
sort(unique(odbcListDrivers()[[1]]))



# configure parameters
Driver = "MySQL ODBC 8.0 Unicode Driver"
Server = "gohawaii.cxvagtspriyp.us-east-1.rds.amazonaws.com"
UID = "admin"
PWD = "cis550-proj"
Port = 3306
Database = "Hawaii"



# connect with AWS
con <- DBI::dbConnect(odbc::odbc(), 
                      Driver = Driver, 
                      Server = Server, 
                      UID = UID, 
                      PWD = PWD, 
                      Port = Port, 
                      Database = Database)

## Run Queries

# query: all routes to Hawaii
airport_list <- SQL("('HNL', 'ITO', 'OGG', 'KOA', 'MKK', 'LNY', 'LIH', 'HNM', 'JHM', 'MUE')")
routes_SQL <- sqlInterpolate(con,
                             "SELECT * FROM Routes WHERE DestinationAirport IN ?list",
                             list = airport_list)
routes_SQL_data <- dbGetQuery(con, routes_SQL)



# query: all airports of Hawaii
arrival_airports_SQL <- sqlInterpolate(con,
                                       "SELECT * FROM Airports WHERE IATA IN ?list",
                                       list = airport_list)
arrival_airports_SQL_data <- dbGetQuery(con, arrival_airports_SQL) 



# query: all airports to Hawaii
departure_airports_SQL <- sqlInterpolate(con,
                                         "WITH r AS (SELECT * FROM Routes WHERE DestinationAirport IN ?list)
                                          SELECT * FROM Airports WHERE IATA IN (SELECT DISTINCT SourceAirport FROM r)",
                                         list = airport_list)
departure_airports_SQL_data <- dbGetQuery(con, departure_airports_SQL) 



# query: all venues of Hawaii
venues_SQL <- sqlInterpolate(con, 
                             "SELECT * FROM Nearby_venues")
venues_SQL_data <- dbGetQuery(con, venues_SQL)

# query: AirBnB in Honolulu County
County <- "Honolulu"
AirBnB_Hawaii_SQL <- sqlInterpolate(con, 
                                    "SELECT * FROM listingsAll"
                                    )
AirBnB_Hawaii_SQL_data <- dbGetQuery(con, AirBnB_Hawaii_SQL)


