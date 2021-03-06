## 1. header -------------------------------
header <- dashboardHeader(title = "Go to Hawaii")

## 2. siderbar ------------------------------
sidebar <- dashboardSidebar(
  width = 260,
  br(),
  sidebarMenu(
    ## 1st tab show the Main dashboard ------------
    menuItem(text = "Overview", 
             tabName = "Overview",
             icon = icon("compass")
    ),
    
    ## 2nd tab show the Flight info ---------------
    menuItem(text = "Flight", 
             tabName = "Flight",
             icon = icon("fighter-jet")
    ),
    
    ## 3rd tab shows Airbnb info ------------------
    menuItem(text = "Airbnb", 
             tabName = "Airbnb",
             icon = icon("house-user")
    ),
    
    ##4th tab shows Attraction info ---------------
    menuItem(text = "Attraction", 
             tabName = "Attraction",
             icon = icon("heart")
    )
    
  )
  
)


## 3. body ----------------------------------------------
body <- dashboardBody(
  tabItems(
    ## 3.1 Overview ------------------------------------
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
              h4("Please select which County you would like to see?", align = "center"),
              position = "right",
              hr(),
              selectInput(
                "county_filter",
                label = h3("Select box"),
                choices = mylist
              )
            )
          ),
          fluidRow(
            gradientBox(
              title = "General Description",
              icon = "fa fa-heart",
              gradientColor = "blue", 
              boxToolSize = "s", 
              footer = description,
              width = 12
            )
          ),
          fluidRow(
            box(
              status = "primary",
              title = "Covid Info",
              solid_header = TRUE,
              dataTableOutput("dF_covid_table"),
              width = 12
            )
          )
        )
      )
    ),
    
    ## 3.2 Flight -------------------------------------------------
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
                      label = h3("Please Select From City:"),
                      choices = departure_airports_cities 
                    )
            ),
            img(src = "flights1.jpg", height = 168, width = 299),
            img(src = "flights2.jpg", height = 168, width = 245),
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
              status = "warning",
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
    ## 3.3 Airbnb info ------------------------------------------------------
    tabItem(
      tabName = "Airbnb",
      tabsetPanel(
        type = "tabs",
        tabPanel(
          title = "Place to Stay",

          fluidRow(
            column (8,
                    sliderInput(inputId = "price_range",
                                label = "Price Range",
                                min = 0,
                                max = 1000,
                                value = c(100,500),
                                width = "220px")
            ),

            img(src = "airbnb1.jpg", height = 168, width = 250),
            img(src = "airbnb2.jpg", height = 168, width = 250),
          ),
          
          fluidRow(
            column(4,
                   selectInput(
                     "neighbourhood_select",
                     label = h3("Neighbourhood"),
                     choices = airbnb_neighbourhood  
                   )
            )
            
          ),
          
          fluidRow(
            column(4,
                   selectInput(
                     "bedroom_select",
                     label = h3("Bedroom"),
                     choices = bedroom_num  
                   )
            ),
            column(4,
                   selectInput(
                     "bathroom_select",
                     label = h3("Bathroom"),
                     choices = bathroom_num   
                   )
            )
            # column(4,
            #        checkboxInput("superhost_check",label = "Superhost"))
          ),
          hr(),
          fluidRow(
            box(
              status = "primary",
              title = "List of recommandations",
              solid_header = TRUE,
              collapsible = TRUE,
              dataTableOutput("dF_airbnb_table"),
              width = 12
            )
          )
        )
      )
    ),
    ## 3.4 Attraction info ------------------------------------------------------
    tabItem(
      tabName = "Attraction",
      tabsetPanel(
        type = "tabs",
        tabPanel(
          title = "Place to see",
          fluidRow(
            column(4,
                   selectInput(
                     "Category_select",
                     label = h3("Category"),
                     choices = venues_categories  
                   )
            ),
            img(src = "attraction1.jpg", height = 168, width = 299),
            img(src = "attraction2.jpg", height = 168, width = 299),
          ),
          hr(),
          fluidRow(
            box(
              status = "primary",
              title = "Attractions",
              solidHeader = TRUE,
              collapsible = TRUE,
              dataTableOutput("dF_venue_table"),
              width = 12
            )
            
          )
        )
      )
    )
  )
)

## 4. put UI together ----------------------------------------------

ui <- dashboardPage(
  header,
  sidebar,
  body
)
