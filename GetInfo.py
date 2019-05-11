import requests
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from bs4 import BeautifulSoup
import re
import pandas as pd
import os

url = 'https://www.remaxrd.com/propiedades/q:%22%22+type:apartment/?'

# create a new Firefox session
driver = webdriver.Firefox(executable_path=r'/home/jeancarlos/Desktop/Proyectos/BienesRaicesRD\geckodriver')

driver.get(url)

soup  = BeautifulSoup(driver.page_source, 'lxml')

info_apartments = {
    'direction': [],
    'price': [],
    'type': [],
    'area': [],
    'bathroom': [],
    'rooms': []
}

aparments = soup.findAll('div', {'class': 'card__content'})

for i in range(len(aparments)):
    print(aparments[i].findAll('p', {'class': 'card__description__title'})[0])
    if 'Apartamento' in aparments[i].findAll('p', {'class': 'card__description__title'})[0].text:

        print(i)
        info_apartments['direction'].append( aparments[i].find('p', {'class': 'card__description__address'}).text )
        info_apartments['price'].append( aparments[i].find('p', {'class': 'card__description__price'}).text )
        info_apartments['type'].append( aparments[i].findAll('p', {'class': 'card__description__title'})[1].text )
        info_apartments['area'].append( aparments[i].find('span', {'class': 'sqm-construction'}).text )
        info_apartments['bathroom'].append( aparments[i].find('span', {'class': 'bathrooms'}).text )
        info_apartments['rooms'].append( aparments[i].find('span', {'class': 'rooms'}).text )

