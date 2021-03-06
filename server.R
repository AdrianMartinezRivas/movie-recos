#server.R

movies <- read.csv("movies.csv", header = TRUE, stringsAsFactors=FALSE)
movies <- movies[with(movies, order(title)), ]
ratings <- read.csv("ratings100k.csv", header = TRUE)

shinyServer(function(input, output) {

  # Text for the 3 boxes showing average scores
    formulaText1 <- reactive({
      paste(input$select)
    })
    formulaText2 <- reactive({
      paste(input$select2)
    })
    formulaText3 <- reactive({
      paste(input$select3)
    })

    output$movie1 <- renderText({
      formulaText1()
    })
    output$movie2 <- renderText({
      formulaText2()
    })
    output$movie3 <- renderText({
      formulaText3()
    })


    # Table containing recommendations
    output$table <- renderTable({

      # Filter for based on genre of selected movies to enhance recommendations
      cat1 <- subset(movies, title==input$select)
      cat2 <- subset(movies, title==input$select2)
      cat3 <- subset(movies, title==input$select3)

      # If genre contains 'Sci-Fi' then  return sci-fi movies
      # If genre contains 'Children' then  return children movies
      if (grepl("Sci-Fi", cat1$genres) | grepl("Sci-Fi", cat2$genres) | grepl("Sci-Fi", cat3$genres)) {
        movies2 <- (movies[grepl("Sci-Fi", movies$genres) , ])
      } else if (grepl("Children", cat1$genres) | grepl("Children", cat2$genres) | grepl("Children", cat3$genres)) {
        movies2 <- movies[grepl("Children", movies$genres), ]
      } else {
        movies2 <- movies[grepl(cat1$genre1, movies$genres)
                          | grepl(cat2$genre1, movies$genres)
                          | grepl(cat3$genre1, movies$genres), ]
      }

      movie_recommendation <- function(input,input2,input3){
        row_num <- which(movies2[,3] == input)
        row_num2 <- which(movies2[,3] == input2)
        row_num3 <- which(movies2[,3] == input3)
        userSelect <- matrix(NA,length(unique(ratings$movieId)))
        userSelect[row_num] <- 5 #hard code first selection to rating 5
        userSelect[row_num2] <- 4 #hard code second selection to rating 4
        userSelect[row_num3] <- 4 #hard code third selection to rating 4
        userSelect <- t(userSelect)

        ratingmat <- dcast(ratings, userId~movieId, value.var = "rating", na.rm=FALSE)
        ratingmat <- ratingmat[,-1]
        colnames(userSelect) <- colnames(ratingmat)
        ratingmat2 <- rbind(userSelect,ratingmat)
        ratingmat2 <- as.matrix(ratingmat2)

        #Convert rating matrix into a sparse matrix
        ratingmat2 <- as(ratingmat2, "realRatingMatrix")

        #Create Recommender Model
        recommender_model <- Recommender(ratingmat2, method = "UBCF",param=list(method="Cosine",nn=30))
        recom <- predict(recommender_model, ratingmat2[1], n=30)
        recom_list <- as(recom, "list")
        recom_result <- data.frame(matrix(NA,30))
        recom_result[1:30,1] <- movies2[as.integer(recom_list[[1]][1:30]),3]
        recom_result <- data.frame(na.omit(recom_result[order(order(recom_result)),]))
        recom_result <- data.frame(recom_result[1:10,])
        colnames(recom_result) <- "User-Based Collaborative Filtering Recommended Titles"
        return(recom_result)
      }

      movie_recommendation(input$select, input$select2, input$select3)

    })

    movie.ratings <- merge(ratings, movies)
    output$tableRatings1 <- renderValueBox({
      movie.avg1 <- summarise(subset(movie.ratings, title==input$select),
                              Average_Rating1 = mean(rating, na.rm = TRUE))
      valueBox(
        value = format(movie.avg1, digits = 3),
        subtitle = input$select,
        icon = if (movie.avg1 >= 3) icon("thumbs-up") else icon("thumbs-down"),
        color = if (movie.avg1 >= 3) "aqua" else "red"
      )

    })

    movie.ratings <- merge(ratings, movies)
    output$tableRatings2 <- renderValueBox({
      movie.avg2 <- summarise(subset(movie.ratings, title==input$select2),
                              Average_Rating = mean(rating, na.rm = TRUE))
      valueBox(
        value = format(movie.avg2, digits = 3),
        subtitle = input$select2,
        icon = if (movie.avg2 >= 3) icon("thumbs-up") else icon("thumbs-down"),
        color = if (movie.avg2 >= 3) "aqua" else "red"
      )
    })

    movie.ratings <- merge(ratings, movies)
    output$tableRatings3 <- renderValueBox({
      movie.avg3 <- summarise(subset(movie.ratings, title==input$select3),
                Average_Rating = mean(rating, na.rm = TRUE))
      valueBox(
        value = format(movie.avg3, digits = 3),
        subtitle = input$select3,
        icon = if (movie.avg3 >= 3) icon("thumbs-up") else icon("thumbs-down"),
        color = if (movie.avg3 >= 3) "aqua" else "red"
      )
    })

    # Generate a table summarizing each players stats
    output$myTable <- renderDataTable({
      movies[c("title", "genres")]
    })

}
)

