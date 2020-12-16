# Aloha Hawaii App
# 
# 
#
# 
#
# 
#

# load libraries
library(tidyverse)
library(DBI)
library(odbc)
library(DT)
library(plotly)
library(leaflet)
library(shiny)
library(shinydashboard)
library(shinydashboardPlus)

# ------------------------------------------------------------------------------
##### connect database #####
# configure parameters
Driver = "MySQL"
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

# query: Overview
overview_SQL <- sqlInterpolate(con,
                               "SELECT * FROM county_overview_1")
overview <- dbGetQuery(con, overview_SQL)
county_list <- sort(unique(overview$County))

# query: Covid
covid1_SQL <- sqlInterpolate(con, 
                             "SELECT * FROM Covid")
covid1 <- dbGetQuery(con, covid1_SQL)
covid1$date <- as.Date(covid1$date, "%m/%d/%y")

covid2_SQL <- sqlInterpolate(con, 
                             "SELECT * FROM Covid2")
covid2 <- dbGetQuery(con, covid2_SQL)
covid2$Date <- as.Date(covid2$Date, "%m/%d/%y")

# query: Flights
arrival_airport <- c('HNL', 'ITO', 'OGG', 'KOA', 'MKK', 'LNY', 'LIH', 'HNM', 'JHM', 'MUE')
arrival_airport_list <- SQL("('HNL', 'ITO', 'OGG', 'KOA', 'MKK', 'LNY', 'LIH', 'HNM', 'JHM', 'MUE')")
routes0_SQL <- sqlInterpolate(con,
                              "WITH _airport as (
                                SELECT Name, City, Country, IATA
                                FROM Airports
                              ),
                                _routes as (
                                SELECT SourceAirport, DestinationAirport
                                FROM RoutesNew
                                WHERE DestinationAirport IN ?list
                              )
                              SELECT r.SourceAirport,
                                     s.Name as SourceAirportName,
                                     s.City as SourceCity,
                                     s.Country as SourceCountry,
                                     r.DestinationAirport,
                                     d.Name as DestinationAirportName,
                                     d.City as DestinationCity,
                                     d.Country as DestinationCountry
                              FROM _routes r
                              JOIN _airport s on r.SourceAirport = s.IATA
                              JOIN _airport d on r.DestinationAirport = d.IATA",
                              list = arrival_airport_list)
non_stop_routes <- dbGetQuery(con, routes0_SQL)

routes1_SQL <- sqlInterpolate(con,
                              "WITH _airport as (
                                 SELECT Name, City, Country, IATA
                                 FROM Airports
                               ),
                                 _routes as (
                                 SELECT SourceAirport, DestinationAirport
                                 FROM RoutesNew
                               )
                               SELECT DISTINCT air2.Name as SourceAirportName,
                                               air2.City as SourceCity,
                                               air2.Country as SourceCountry,
                                               air3.Name as TransferAirportName,
                                               air3.City as TransferCity,
                                               air3.Country as TransferCountry,
                                               air1.Name as DestinationAirportName,
                                               air1.City as DestinationCity,
                                               air1.Country as DestinationCountry
                               FROM _routes r1 JOIN _routes r2
                                 ON r1.DestinationAirport = r2.SourceAirport
                               JOIN _airport air1
                                 ON r2.DestinationAirport = air1.IATA
                               JOIN _airport air2
                                 ON r1.SourceAirport = air2.IATA
                               JOIN _airport air3
                                 ON r1.DestinationAirport = air3.IATA
                               WHERE r1.SourceAirport != r1.DestinationAirport
                                 AND r1.SourceAirport != r2.DestinationAirport
                                 AND r1.DestinationAirport != r2.DestinationAirport
                                 AND r2.DestinationAirport IN ?list ",
                              list = arrival_airport_list)
one_stop_routes <- dbGetQuery(con, routes1_SQL)
departure_airports_cities <- non_stop_routes %>%
    filter(!SourceAirport %in% arrival_airport) %>%
    distinct(SourceCity)

# query: AirBnB
airBnB_SQL <- sqlInterpolate(con,
                             "SELECT listing_url,
                                     name,
                                     neighbourhood_cleansed,
                                     neighbourhood_group_cleansed,
                                     latitude,
                                     longitude,
                                     property_type,
                                     bathrooms,
                                     bedrooms,
                                     price,
                                     review_scores_rating,
                                     reviews_per_month
                              FROM listingsAll")
airBnB <- dbGetQuery(con, airBnB_SQL)
airbnb_neighbourhood <- sort(unique(airBnB$neighbourhood_cleansed))
bedroom_num <- sort(unique(airBnB$bedrooms))
bathroom_num <- sort(unique(airBnB$bathrooms))

# query: Venues
venues_SQL <- sqlInterpolate(con,
                             "SELECT * FROM Venues")
venues <- dbGetQuery(con, venues_SQL)
venues_city <- sort(unique(venues$city))



# ------------------------------------------------------------------------------
##### define UI #####
# 1. header
header <- dashboardHeader(title = "Aloha Hawaii")

# 2. siderbar
sidebar <- dashboardSidebar(
    width = 260,
    br(),
    sidebarMenu(
        ## 1st tab show the Main dashboard
        menuItem(text = "Overview", 
                 tabName = "Overview",
                 icon = icon("compass")
        ),
        
        ## 2nd tab show the Flight info
        menuItem(text = "Flights", 
                 tabName = "Flight",
                 icon = icon("fighter-jet")
        ),
        
        ## 3rd tab shows Airbnb info
        menuItem(text = "Vacation Rentals", 
                 tabName = "Airbnb",
                 icon = icon("house-user")
        ),
        
        ##4th tab shows Attraction info
        menuItem(text = "Popular Places", 
                 tabName = "Attraction",
                 icon = icon("heart")
        )
        
    )
    
)

# 3. body 
body <- dashboardBody(
    tabItems(
        ## 3.1 Overview
        tabItem(
            tabName = "Overview",
            tabsetPanel(
                type = "tabs",
                tabPanel(
                    title = "Hawaii",
                    fluidRow(
                        column (
                            width = 8,
                            valueBoxOutput("progressBox1", width = 5),
                            valueBoxOutput("progressBox2", width = 5),
                            valueBoxOutput("progressBox3", width = 5),
                            valueBoxOutput("progressBox4", width = 5)
                        ),
                        
                        sidebarPanel(
                            position = "right",
                            hr(),
                            selectInput(
                                "county_filter",
                                label = h3("Select which county you would like to see"),
                                choices = county_list
                            )
                        )
                    ),
                    
                    fluidRow(
                        gradientBox(
                            title = "General Description",
                            icon = "fa fa-heart",
                            gradientColor = "blue", 
                            boxToolSize = "s", 
                            footer = textOutput("description"),
                            width = 12
                        )
                    ),
                    
                    fluidRow(
                        box(
                            status = "primary",
                            title = "Covid Info: Cumulative number of cases over time",
                            solid_header = TRUE,
                            plotlyOutput("cumulative_cases_plot"),
                            width = 6
                        ),
                        box(
                            status = "info",
                            title = "Covid Info: New number of cases over time",
                            solid_header = TRUE,
                            plotlyOutput("new_cases_plot"),
                            width = 6
                        )
                    )
                )
            )
        ),
        
        ## 3.2 Flight info
        tabItem(
            tabName = "Flight",
            tabsetPanel(
                type = "tabs",
                tabPanel(
                    title = "Flights to Hawaii",
                    fluidRow(
                        column (5, 
                                selectInput(
                                    "flight_from_select", 
                                    label = h3("Please select a source city:"),
                                    choices = departure_airports_cities 
                                )
                        ),
                    ),
                    
                    hr(),
                    fluidRow(
                        box(
                            status = "primary",
                            title = "Non-stop Flights",
                            solidHeader = TRUE,
                            collapsible = TRUE,
                            dataTableOutput("dF_non_stop_flight_table"),
                            width = 12
                        )
                    ),
                    hr(),
                    fluidRow(
                        box(
                            status = "info",
                            title = "One-stop Transfer Flights",
                            solidHeader = TRUE,
                            collapsible = TRUE,
                            dataTableOutput("dF_one_stop_flight_table"),
                            width = 12
                        )
                    )
                )
            )
        ),
        
        ## 3.3 Airbnb info
        tabItem(
            tabName = "Airbnb",
            tabsetPanel(
                type = "tabs",
                tabPanel(
                    title = "Place to Stay",
                    
                    fluidRow(
                        column (3,
                                sliderInput(inputId = "price_range",
                                            label = "Price Range",
                                            min = 0,
                                            max = 1000,
                                            value = c(0,600))
                        ),
                        column(3,
                               selectInput(
                                   "neighbourhood_select",
                                   label = h3("Neighbourhood"),
                                   choices = airbnb_neighbourhood  
                               )
                        ),
                        column(3,
                               selectInput(
                                   "bedroom_select",
                                   label = h3("Bedroom"),
                                   choices = bedroom_num  
                               )
                        ),
                        column(3,
                               selectInput(
                                   "bathroom_select",
                                   label = h3("Bathroom"),
                                   choices = bathroom_num   
                               )
                        )
                    ),
                    
                    hr(),
                    fluidRow(
                        box(
                            status = "primary",
                            title = "List of recommandations",
                            collapsible = TRUE,
                            dataTableOutput("dF_airbnb_table", height = 630),
                            width = 6
                        ),
                        box(
                            status = "info",
                            title = "AirBnB",
                            collapsible = TRUE,
                            leafletOutput("airbnbMap", height = 630),
                            width = 6
                        )
                    )
                )
            )
        ),
        
        ## 3.4 Attraction info
        tabItem(
            tabName = "Attraction",
            tabsetPanel(
                type = "tabs",
                tabPanel(
                    title = "Place to See",
                    
                    fluidRow(
                        column(4,
                               selectInput(
                                   "city_select",
                                   label = h3("City"),
                                   choices = venues_city  
                               )
                        ),
                    ),
                    
                    hr(),
                    fluidRow(
                        box(
                            status = "primary",
                            title = "Attractions",
                            solidHeader = TRUE,
                            collapsible = TRUE,
                            leafletOutput("venuesMap", height = 630),
                            width = 12
                        )
                        
                    )
                )
            )
        )
    )
)

# 4. put UI together
ui <- dashboardPage(
    header,
    sidebar,
    body
)



# ------------------------------------------------------------------------------
##### define server #####
server <- function(input, output) {
    
    # render value box for Overview info
    pop <- reactive({
        filter(overview, County == input$county_filter)$Population
    })
    
    area <- reactive({
        filter(overview, County == input$county_filter)$Area
    })
    
    flower <- reactive({
        filter(overview, County == input$county_filter)$Flower
    })
    
    settle <- reactive({
        filter(overview, County == input$county_filter)$Largest_Settlement
    })
    
    output$progressBox1 <- renderValueBox({
        valueBox(
            pop(), 
            "Population", 
            icon = icon("users"),
            color = "aqua"
        )
    })
    
    output$progressBox2 <- renderValueBox({
        valueBox(
            area(), 
            "Area Sqr Fts", 
            icon = icon("home"),
            color = "purple"
        )
    })
    
    output$progressBox3 <- renderValueBox({
        valueBox(
            flower(), 
            "Official Flower", 
            icon = icon("fan"),
            color = "light-blue"
        )
    })
    
    output$progressBox4 <- renderValueBox({
        valueBox(
            settle(), 
            "Largest Settlement", 
            icon = icon("user"),
            color = "blue"
        )
    })
    
    output$description <- renderText({
        filter(overview, County == input$county_filter)$Description
    })
    
    # render plot for Covid info
    output$cumulative_cases_plot <- renderPlotly({
        cumulative_cases0 <- covid1 %>% 
            filter(county != "Unknown") %>%
            ggplot(aes(x = date,
                       y = cumulative_cases,
                       color = county,
                       group = 1)) +
            geom_line() +
            labs(color = "county") +
            facet_wrap(~county, ncol = 2) +
            theme_minimal() +
            theme(axis.title.x=element_blank(), 
                  axis.title.y=element_blank(),
                  legend.position = "none")
        cumulative_cases1 <- ggplotly(cumulative_cases0)
        cumulative_cases1
    })
    
    output$new_cases_plot <- renderPlotly({
        new_cases0 <- covid2 %>% 
            filter(County != "Missing") %>%
            ggplot(aes(x = Date,
                       y = New_Cases,
                       color = County,
                       group = 1)) +
            geom_line() +
            labs(color = "County") +
            facet_wrap(~County, ncol = 2) +
            theme_minimal() +
            theme(axis.title.x=element_blank(), 
                  axis.title.y=element_blank(),
                  legend.position = "none")
        new_cases1 <- ggplotly(new_cases0)
        new_cases1
    })
    
    # render table for Flight info
    output$dF_non_stop_flight_table <- renderDataTable({
        non_stop_routes %>% 
            filter(SourceCity == input$flight_from_select) %>%
            distinct_all()
    })
    
    output$dF_one_stop_flight_table <- renderDataTable({
        one_stop_routes %>%
            filter(SourceCity == input$flight_from_select) %>%
            distinct_all()
    })
    
    # render map and table for Airbnb info
    output$dF_airbnb_table <- renderDataTable({
        selected_airbnb <- filter(airBnB, 
                                  neighbourhood_cleansed == input$neighbourhood_select,
                                  bedrooms == input$bedroom_select, 
                                  bathrooms ==input$bathroom_select,
                                  price>=input$price_range[1],price<=input$price_range[2])
        selected_airbnb %>% 
            mutate(url = paste("<a href='", selected_airbnb$listing_url, "'>", selected_airbnb$listing_url, "</a>")) %>%
            arrange(desc(review_scores_rating), desc(reviews_per_month)) %>%
            select(url, 
                   price,
                   bedrooms, 
                   bathrooms, 
                   review_scores_rating) 
    }, escape = FALSE)
    
    output$airbnbMap <- renderLeaflet({
        selected_airbnb <- filter(airBnB, 
                                  neighbourhood_cleansed == input$neighbourhood_select,
                                  bedrooms == input$bedroom_select, 
                                  bathrooms ==input$bathroom_select,
                                  price>=input$price_range[1],price<=input$price_range[2])
        m <- leaflet(selected_airbnb) %>%
            setView(lat = mean(selected_airbnb$latitude), lng = mean(selected_airbnb$longitude), zoom = 12)
        m %>%
            addTiles() %>%
            addAwesomeMarkers(lat = ~latitude, lng = ~longitude,
                              popup = paste("<b>Name: </b>", selected_airbnb$name, "<br>",
                                            "<b>Price: </b>", selected_airbnb$price, "<br>",
                                            "<b>Url: </b>", "<a href='", selected_airbnb$listing_url, "'>", selected_airbnb$listing_url, "</a>", "<br>", seq=""))
    })

    # render map for Attraction info
    output$venuesMap <- renderLeaflet({
        selected_venues <- filter(venues, city == input$city_select)
        m <- leaflet(selected_venues) %>%
            setView(lat = mean(selected_venues$lat), lng = mean(selected_venues$lng), zoom = 12)
        m %>% 
            addTiles() %>% 
            addAwesomeMarkers(lat = ~lat, lng = ~lng, 
                              popup = paste("<b>Name: </b>", selected_venues$name, "<br>",
                                            "<b>Category: </b>", selected_venues$categories, "<br>",
                                            "<b>Address: </b>", selected_venues$formattedAddress, "<br>", seq=""))
    })
}


# ------------------------------------------------------------------------------
# run application 
shinyApp(ui = ui, server = server)
