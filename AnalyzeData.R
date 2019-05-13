library(dplyr)
library(ggplot2)
library(GGally)
library(skimr)

apartment_df = read.csv('Apartment.csv', stringsAsFactors = FALSE)

apartment_df['moneda'] = substr(apartment_df$price, 1, 2)
apartment_df['price_num'] = gsub(pattern = ",", "", substr(apartment_df$price, 4, length(apartment_df$price)) ) %>% 
  as.numeric()
apartment_df['price_dop'] = ifelse(apartment_df$moneda == 'RD', apartment_df$price_num, apartment_df$price_num*50)
apartment_df['area_num'] = gsub(pattern = "[,mt]", replacement = "", apartment_df$area) %>% 
  as.numeric()
apartment_df['bathroom'] = apartment_df$bathroom %>% as.numeric()
apartment_df['rooms'] = apartment_df$rooms %>% as.numeric()

apartment_df %>% 
  ggplot(aes(x = direction, y = price_dop)) +
  geom_boxplot()

apartment_df %>% str
apartment_df %>% skim




apartment_df %>% 
  select(area_num, price_dop, rooms, bathroom) %>%
  cor(use = "complete.obs")

apartment_df %>% 
  select(area_num, price_dop, rooms, bathroom) %>% 
  ggpairs()

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