library(leaflet.extras)

pal <- colorNumeric(
  palette = "YlGnBu",
  domain = apartment_df_clean_venta %>% 
    filter(price_dop <= 20000000) %>% `$`(price_dop)
)

m <- apartment_df_clean_venta %>% 
  filter(price_dop <= 20000000) %>% 
  leaflet() %>%
  addTiles() %>%
  addCircles(color = ~pal(price_dop)) %>% 
  addLegend(pal = pal, values = ~price_dop)
m
