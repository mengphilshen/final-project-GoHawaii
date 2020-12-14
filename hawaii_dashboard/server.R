server <- function(input, output) {
  
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
  
  output$dF_covid_table <- DT::renderDataTable(
    filter(covid, County == input$county_filter)
  )
  
  # render value box for flight information ---------------------------------
  output$dF_non_stop_flight_table <- DT::renderDataTable(
    filter(non_stop_routes_SQL_data, SourceCity == input$flight_from_select)
  )
  
  output$dF_one_stop_flight_table <- DT::renderDataTable(
    filter(one_stop_routes_SQL_data, SourceCity == input$flight_from_select)
  )
  
  # render value box for venues information ----------------------------------
  output$dF_venue_table <- DT::renderDataTable(
    filter(venues_SQL_data2, categories == input$Category_select)
  )
  
  # render value box for airbnb information ---------------------------------
  output$dF_airbnb_table <- DT::renderDataTable(
    filter(airBnB_SQL_data, neighbourhood_group_cleansed == input$neighbourhood_select,
           property_type == input$type_select,
           bedrooms == input$bedroom_select, 
           bathrooms_text ==input$bathroom_select,
           price>=input$price_range[1],price<=input$price_range[2])
  )
}
