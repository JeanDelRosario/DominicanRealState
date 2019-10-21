from selenium import webdriver
from bs4 import BeautifulSoup
import pandas as pd
import numpy as np
import time

url = 'https://www.remaxrd.com/propiedades/q:%22%22+type:apartment/?'

# Download geckodriver and put the path in this variable
geckodriver_path = r'D:/geckodriver-v0.26.0-win64/geckodriver.exe'

# create a new Firefox session
driver = webdriver.Firefox(executable_path=geckodriver_path)

driver.get(url)



info_apartments = {
    'direction': [],
    'price': [],
    'type': [],
    'area': [],
    'bathroom': [],
    'rooms': []
}



for page in range(2, 10):
    print(page)

    soup = BeautifulSoup(driver.page_source, 'lxml')

    aparments = soup.findAll('div', {'class': 'card__content'})

    for i in range(len(aparments)):

        print(aparments[i].findAll('p', {'class': 'card__description__title'})[0])

        if 'Apartamento' in aparments[i].findAll('p', {'class': 'card__description__title'})[0].text:

            print(i)
            info_apartments['direction'].append( aparments[i].find('p', {'class': 'card__description__address__mansory'}).text )
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

# Adding coordinates
info_apartments_df = pd.read_csv('Apartment.csv')
info_apartments_df['latitude'] = 0
info_apartments_df['longitude'] = 0


from geopy.geocoders import Nominatim

geolocator = Nominatim(user_agent="RealState")


def geocode(address):
    try:
        location = geolocator.geocode(address)

        # if it returns a location
        if location is not None:
            # return those values
            return [location.latitude, location.longitude]
        else:
            return ['null', 'null']
    except Exception as err:
        print('Got first exception')
        print(err)
        time.sleep(10)
        try:
            location = geolocator.geocode(address)

            # if it returns a location
            if location is not None:
                # return those values
                return [location.latitude, location.longitude]
            else:
                return ['null', 'null']
        except Exception as err:
            print('Got second exception')
            print(err)
            # catch whatever errors, likely timeout, and return null values
            print(err)
            return ['null', 'null']


address_list = []
address_dict = {}


for address in info_apartments_df['direction']:
    print(address)

    if address in address_dict:
        print('Already in dict')
        address_list.append(address_dict[address])

    else:
        address_ = geocode(address)

        if address_[0] != 'null':
            address_dict[address] = address_

        address_list.append(address_)

    time.sleep(2)

info_apartments_df['latitude'] = [address[0] for address in address_list]
info_apartments_df['longitude'] = [address[1] for address in address_list]

info_apartments_df[info_apartments_df.latitude == 'null']

info_apartments_df[info_apartments_df.direction == 'Ensanche Naco, Santo Domingo De Guzmán']

np.unique(info_apartments_df.direction)

info_apartments_df.to_csv('Apartment.csv')