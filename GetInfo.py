from selenium import webdriver
from bs4 import BeautifulSoup
import pandas as pd
import time

url = 'https://www.remaxrd.com/propiedades/q:%22%22+type:apartment/?'

# create a new Firefox session
driver = webdriver.Firefox(executable_path=r'/home/jeancarlos/Desktop/Proyectos/BienesRaicesRD/DominicanRealState/geckodriver')

driver.get(url)



info_apartments = {
    'direction': [],
    'price': [],
    'type': [],
    'area': [],
    'bathroom': [],
    'rooms': []
}



for page in range(2, 200):
    print(page)

    soup = BeautifulSoup(driver.page_source, 'lxml')

    aparments = soup.findAll('div', {'class': 'card__content'})

    for i in range(len(aparments)):

        print(aparments[i].findAll('p', {'class': 'card__description__title'})[0])

        if 'Apartamento' in aparments[i].findAll('p', {'class': 'card__description__title'})[0].text:

            print(i)
            info_apartments['direction'].append( aparments[i].find('p', {'class': 'card__description__address'}).text )
            info_apartments['price'].append( aparments[i].find('p', {'class': 'card__description__price'}).text )
            info_apartments['type'].append( aparments[i].findAll('p', {'class': 'card__description__title'})[1].text )
            try:
                info_apartments['area'].append( aparments[i].find('span', {'class': 'sqm-construction'}).text )
            except AttributeError as error:
                info_apartments['area'].append( 'Unknown' )

            try:
                info_apartments['bathroom'].append( aparments[i].find('span', {'class': 'bathrooms'}).text )
            except AttributeError as error:
                info_apartments['bathroom'].append( 'Unknown' )

            try:
                info_apartments['rooms'].append( aparments[i].find('span', {'class': 'rooms'}).text )
            except AttributeError as error:
                info_apartments['rooms'].append( 'Unknown' )

    time.sleep(3)

    btn = driver.find_element_by_xpath('//a[@aria-label="Page {}"]'.format(page))

    btn.click()

    time.sleep(5)



info_apartments_df = pd.DataFrame(info_apartments)

info_apartments_df.to_csv('Apartment.csv')