# R library
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

# database library
library(DBI)
library(odbc)
# data library
library(tidyverse)


# check drivers
sort(unique(odbcListDrivers()[[1]]))


## Connect Database
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

## Run Query to get overall data
overview_SQL <- sqlInterpolate(con, 
                           "select * from county_overview_1")
overview <- dbGetQuery(con, overview_SQL)

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

## get all the counties
mylist <- as.list(overview["County"])

## 
description <- overview[1, "Description"]

## Run Query to get overall covid data
covid_SQL <- sqlInterpolate(con, 
                        "select * from Covid
                        order by date desc")
covid <- dbGetQuery(con, covid_SQL)

names(covid) <- c('indx','Date',
                  'County',
                  'State',
                  'Federal_ID',
                  'Cumulative_Cases',
                  'Cumulative_Death')
covid$County = str_trim(covid$County)


## Run Queries to get fligts data---------------------------------------------

# query: all non stop routes to Hawaii
airport_list <- SQL("('HNL', 'ITO', 'OGG', 'KOA', 'MKK', 'LNY', 'LIH', 'HNM', 'JHM', 'MUE')")
routes_SQL <- sqlInterpolate(con,
                             "WITH _airport as (
                                SELECT Name, City, Country, IATA
                                FROM Airports
                            ),
                                _routes as (
                                SELECT SourceAirport, DestinationAirport
                                FROM Routes
                                WHERE DestinationAirport IN ?list
                            )
                            SELECT r.SourceAirport, s.Name as SourceAirportName, s.City as SourceCity, s.Country as SourceCountry, 
                               r.DestinationAirport, d.Name as DestinationAirportName, d.City as DestinationCity, d.Country as DestinationCountry
                               FROM _routes r
                            JOIN _airport s on r.SourceAirport = s.IATA
                            JOIN _airport d on r.DestinationAirport = d.IATA",
                             list = airport_list)
non_stop_routes_SQL_data <- dbGetQuery(con, routes_SQL)

# Here is a list of Departure city to choose from
dat <- non_stop_routes_SQL_data[!(non_stop_routes_SQL_data$SourceAirport %in% c('HNL', 'ITO', 'OGG', 'KOA', 'MKK', 'LNY', 'LIH', 'HNM', 'JHM', 'MUE')),]
departure_airports_cities <- sort(unique(dat$SourceCity))


# query: all 1 stop routes to Hawaii
routes_one_SQL <- sqlInterpolate(con,
                                 "WITH _airport as (
                                      SELECT Name, City, Country, IATA
                                      FROM Airports
                                  ),
                                      _routes as (
                                      SELECT SourceAirport, DestinationAirport
                                      FROM Routes
                                  )
                                  SELECT DISTINCT   air2.Name as SourceAirportName,
                                                   air2.City as SourceCity, air2.Country as SourceCountry,
                                                    air3.Name as TransferAirportName,
                                                   air3.City as TransferCity, air3.Country as TransferCountry,
                                                    air1.Name as DestinationAirportName,
                                                   air1.City as DestinationCity, air1.Country as DestinationCountry
                                  FROM _routes r1 JOIN _routes r2 ON r1.DestinationAirport = r2.SourceAirport
                                                  JOIN _airport air1 ON r2.DestinationAirport = air1.IATA
                                                  JOIN _airport air2 ON r1.SourceAirport = air2.IATA
                                                  JOIN _airport air3 ON r1.DestinationAirport = air3.IATA
                                  WHERE r1.SourceAirport != r1.DestinationAirport
                                      AND r1.SourceAirport != r2.DestinationAirport
                                      AND r1.DestinationAirport != r2.DestinationAirport
                                      AND r2.DestinationAirport IN ?list ",
                                 list = airport_list)
one_stop_routes_SQL_data <- dbGetQuery(con, routes_one_SQL)

# query: all AirBnB
airBnB_SQL <- sqlInterpolate(con,
                                 "select
                                        neighbourhood_group_cleansed,
                                        property_type,
                                        bedrooms,
                                        beds,
                                        amenities,
                                        price,
                                        review_scores_rating,
                                        reviews_per_month
                                        from Hawaii.Listing l LEFT JOIN Hawaii.Score s ON l.id = s.id
                                        order by s.review_scores_rating desc")
airBnB_SQL_data <- dbGetQuery(con, airBnB_SQL)


# query: all venues of Hawaii
venues_SQL <- sqlInterpolate(con, 
                             "SELECT * FROM Nearby_venues")
venues_SQL_data <- dbGetQuery(con, venues_SQL)
venues_SQL_data2 <- venues_SQL_data[, c('name', 'categories', 'city', 'address', 'county')]
venues_categories <- sort(unique( venues_SQL_data2$categories ))
venues_county <- sort(unique( venues_SQL_data2$county ))