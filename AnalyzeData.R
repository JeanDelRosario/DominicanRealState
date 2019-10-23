# The main discovery I want to make is what are the principal drivers in dominican republic apartment prices
# I'll be examining mainly 3 variables for this:
# Area, amount of bathrooms and rooms


library(dplyr)
library(ggplot2)
library(gridExtra)
library(GGally)
library(skimr)

# Get and format the data
apartment_df = read.csv('Apartment.csv', stringsAsFactors = FALSE)

apartment_df['moneda'] = substr(apartment_df$price, 1, 2)
apartment_df['price_num'] = gsub(pattern = ",", "", substr(apartment_df$price, 4, length(apartment_df$price)) ) %>% 
  as.numeric()
apartment_df['price_dop'] = ifelse(apartment_df$moneda == 'RD', apartment_df$price_num, apartment_df$price_num*50)
apartment_df['area_num'] = gsub(pattern = "[,mt]", replacement = "", apartment_df$area) %>% 
  as.numeric()
apartment_df['bathroom'] = apartment_df$bathroom %>% as.numeric()
apartment_df['rooms'] = apartment_df$rooms %>% as.numeric()
apartment_df['latitude'] = apartment_df$latitude %>% as.numeric()
apartment_df['longitude'] = apartment_df$longitude %>% as.numeric()

# Analyze the data a bit
apartment_df %>%
  skim

# Plot the data
apartment_df %>% 
  select(area_num, price_dop, rooms, bathroom) %>% 
  ggpairs()

# As we can see we have some big outliers in the data.
# What I like to do is to take them out as they can be just some errors in the data (as we got it just from 
# web scrapping) or maybe it's data that can offer us some other useful insights.
# For now let's just take it out and continue.

apartment_df_sell <- apartment_df %>% 
  filter(area_num > 0 & area_num < 2500 & bathroom < 10 & price_dop > 0 & price_dop < 1e+10/4 & rooms < 12) %>% 
  filter(type == "Venta")

# Let's scan the data again and run some correlations

apartment_df_sell %>%
  skim

apartment_df_sell %>% 
  select(area_num, price_dop, rooms, bathroom) %>% 
  ggpairs()


# Taking a quick glance it's easy to see a small group of really pricy apartments which also appear to be
# really big judging by the area.
# Looking at the correlation between rooms and price it seems a bit off that it;s lower than the correlation
# between  bathrooms and price, inspecting this closer looking at the graph we can see that some apartments are
# on the low side in price but have more than 5 rooms. It's something worth investigating further later on.

# Now let's build some linear models to see how well we can predict the price of the apartments.

# I'll just keep it simple and build PCA regression and a regularized regression.

# We'll do it the machine learning way by dividing into trainning and testing, because I don't think I can
# get much explanation of the parameters since all the variables are so highly correlated.

library(caret)

index <- createDataPartition(apartment_df_sell$price_dop, p=0.6, list = F)
train <- apartment_df_sell[ index, ]
test <- apartment_df_sell[-index, ]


# regularized regression
lasso <- train(price_dop ~ bathroom + area_num + rooms,
               data = train,
             method = 'glmnet',
             preProcess = c("center", "scale"),
             tuneLength = 10
)

# PCA

pca_reg <- train(price_dop ~ bathroom + area_num + rooms,
               data = train,
               method = 'glm',
               preProcess = c("center", "scale", "pca"),
               trControl = trainControl(preProcOptions = list(pcaComp = 2)),
               tuneLength = 1
)


# Plot predictions vs reality in testing set
test$price_dop_lasso <- predict(lasso, test)
test$price_dop_pca <- predict(pca_reg, test)


lasso_plot <- test %>% 
  ggplot(aes(x = price_dop, y = price_dop_lasso)) +
  geom_point()

pca_plot <- test %>% 
  ggplot(aes(x = price_dop, y = price_dop_pca)) +
  geom_point()

grid.arrange(lasso_plot, pca_plot, nrow = 1)



# Let's do the same but only for houses that are worth less than DOP 20,000,000



apartment_df_sell_v2 <- apartment_df %>% 
  filter(area_num > 0 & area_num < 2500 & bathroom < 10 & price_dop > 0 & price_dop < 2e+7 & rooms < 12) %>% 
  filter(type == "Venta")

# Let's scan the data again and run some correlations

apartment_df_sell_v2 %>%
  skim

apartment_df_sell_v2 %>% 
  select(area_num, price_dop, rooms, bathroom) %>% 
  ggpairs()


# Taking a quick glance it's easy to see a small group of really pricy apartments which also appear to be
# really big judging by the area.
# Looking at the correlation between rooms and price it seems a bit off that it;s lower than the correlation
# between  bathrooms and price, inspecting this closer looking at the graph we can see that some apartments are
# on the low side in price but have more than 5 rooms. It's something worth investigating further later on.

# Now let's build some linear models to see how well we can predict the price of the apartments.

# I'll just keep it simple and build PCA regression and a regularized regression.

# We'll do it the machine learning way by dividing into trainning and testing, because I don't think I can
# get much explanation of the parameters since all the variables are so highly correlated.

library(caret)

index <- createDataPartition(apartment_df_sell_v2$price_dop, p=0.6, list = F)
train <- apartment_df_sell_v2[ index, ]
test <- apartment_df_sell_v2[-index, ]


# regularized regression
lasso <- train(price_dop ~ bathroom + area_num + rooms,
               data = train,
               method = 'glmnet',
               preProcess = c("center", "scale"),
               tuneLength = 10
)

# PCA

pca_reg <- train(price_dop ~ bathroom + area_num + rooms,
                 data = train,
                 method = 'glm',
                 preProcess = c("center", "scale", "pca"),
                 trControl = trainControl(preProcOptions = list(pcaComp = 2)),
                 tuneLength = 1
)


# Plot predictions vs reality in testing set
test$price_dop_lasso <- predict(lasso, test)
test$price_dop_pca <- predict(pca_reg, test)


lasso_plot <- test %>% 
  ggplot(aes(x = price_dop, y = price_dop_lasso)) +
  geom_point()

pca_plot <- test %>% 
  ggplot(aes(x = price_dop, y = price_dop_pca)) +
  geom_point()

grid.arrange(lasso_plot, pca_plot, nrow = 1)



# Looking at the plots, the predictions dont look that good.
# The variance in the predictions plots doesn't looks constant which let's me
# to believe that we are missing some predictors.
# I have latitude and longitude but they are not that clean
# I'll try using them anyways to see what happens.

apartment_df_sell_v3 <- apartment_df %>% 
  filter(area_num > 0 &
           area_num < 2500 &
           bathroom < 10 &
           price_dop > 0 &
           price_dop < 2e+7 &
           rooms < 12 &
           latitude >= 17.54 & latitude <= 19.96 &
           longitude >= -71.84 & longitude <= -68.35) %>% 
  filter(type == "Venta") %>% 
  mutate(longitude = longitude,
         latitude = latitude)


index <- createDataPartition(apartment_df_sell_v3$price_dop, p=0.6, list = F)
train <- apartment_df_sell_v3[ index, ]
test <- apartment_df_sell_v3[-index, ]


# regularized regression
lasso <- train(price_dop ~ bathroom + area_num + rooms + latitude + longitude,
               data = train,
               method = 'glmnet',
               preProcess = c("center", "scale"),
               tuneLength = 10
)

# PCA

pca_reg <- train(price_dop ~ bathroom + area_num + rooms + latitude + longitude,
                 data = train,
                 method = 'glm',
                 preProcess = c("center", "scale", "pca"),
                 trControl = trainControl(preProcOptions = list(pcaComp = 2)),
                 tuneLength = 1
)


# Plot predictions vs reality in testing set
test$price_dop_lasso <- predict(lasso, test)
test$price_dop_pca <- predict(pca_reg, test)


lasso_plot <- test %>% 
  ggplot(aes(x = price_dop, y = price_dop_lasso)) +
  geom_point()

pca_plot <- test %>% 
  ggplot(aes(x = price_dop, y = price_dop_pca)) +
  geom_point()

grid.arrange(lasso_plot, pca_plot, nrow = 1)


# For now we'll only analyze the apartments that are for sale and their price it's bellow DOP 20,000,000



apartment_df %>% 
  select(area_num, price_dop, rooms, bathroom) %>%
  cor(use = "complete.obs")



apartment_df_clean <- apartment_df %>% 
  filter(area_num > 0 & area_num < 10000 & bathroom < 20 & price_dop > 0 & price_dop < 300000000 & rooms < 20) %>% 
  filter(type == "Venta")

apartment_df_clean %>% 
  skim

apartment_df_clean %>% 
  select(area_num, price_dop, rooms, bathroom) %>% 
  ggpairs()

apartment_df_clean %>% 
  select(area_num, price_dop, rooms, bathroom) %>% 
  filter(price_dop < 200000000) %>% 
  ggpairs()