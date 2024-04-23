## PS: SSL protocols used in these get requests NOT supported in conda base env. Use any other virtual env

import requests
import os
import datetime as dt
import time
import pandas as pd
import piexif

# Epicollect5 API: https://developers.epicollect.net

# Token authorization from the Epicollect API expires 2 hours after request
# Some request limits to keep in mind:
# # 60 requests per minute for entries.
# # 30 requests per minute for media files.
# # 1000 entries per request.

# Some logistics first
myWD = os.getcwd()
# destinationPath = r"Z:\BayneLabWorkSpace\Mobile Photos 2022"
destinationPath = r"...\Epicollect-MediaRequest\Bat"

# Media request: GET /api/export/media/{project_slug}?{key=value&key=value...}
PROJECT = "bu-deployment-2022"

os.chdir(destinationPath)
with open("Main Log.txt", 'w') as f:
    f.write(f"Launching script {str(dt.datetime.now())} \n")

# Access token expires after 2 hours
# Add in your own client credentials
def get_auth_token():
    # Media request: GET /api/export/media/{project_slug}?{key=value&key=value...}
    credentials = {'grant_type': 'client_credentials',
                'client_id': ...,
                'client_secret': '...'}

    ACCESS_TOKEN = requests.post('https://five.epicollect.net/api/oauth/token', json=credentials).json()['access_token']
    return ACCESS_TOKEN

os.chdir(os.path.join(myWD, 'Data'))
data = pd.read_csv(r"...\Epicollect-MediaRequest\Data\bat_site_photos.csv")
# dataColumns = [col for col in data.columns]

AllLocations = data['location'].to_list()

def make_folders_per_location():
    os.chdir(destinationPath)
    created_folders = []
    failed_folders = []
    for i in range(len(AllLocations)):
        loc = AllLocations[i]
        if not os.path.exists(loc):
            os.makedirs(loc)
            with open(f"{os.path.join(destinationPath, loc)}/Download Log.txt", 'w') as f:
                f.write(f"Image download log for {loc} \n")

            created_folders.append(loc)
        else:
            failed_folders.append(loc)
    os.chdir(destinationPath)
    with open("Main log.txt", 'a') as f:
        f.write("The following locations have a folder: \n" )
        f.write(f"{created_folders} \n\n")
        f.write("The following locations failed to make a folder: \n")
        f.write(f"{failed_folders} \n\n")
    return

# make a separate dataframe with the site name, and only photos columns
mediaDF = data[['location', 'ARU',
 'GPS','North','East','South','West', 'Canopy',
 'Ground','Bat ARU Setup 1', 'Bat ARU Setup 2']]
imageColumms = ['ARU',
 'GPS','North','East','South','West', 'Canopy',
 'Ground','Bat ARU Setup 1', 'Bat ARU Setup 2']

def adjust_exif_date(correct_date, file_path):
    exif_dict = piexif.load(file_path)
    new_date = dt(2018, 1, 1, 0, 0, 0).strftime("%Y:%m:%d %H:%M:%S")
    ## is the date in the correct format?
    exif_dict['0th'][piexif.ImageIFD.DateTime] = correct_date
    exif_dict['Exif'][piexif.ExifIFD.DateTimeOriginal] = correct_date
    exif_dict['Exif'][piexif.ExifIFD.DateTimeDigitized] = correct_date
    exif_bytes = piexif.dump(exif_dict)
    piexif.insert(exif_bytes, file_path)
    return

def download_and_store_media():
    # request limit: 30 media files per minute. Sleep 2 seconds after each download to avoid halt
    ACCESS_TOKEN = get_auth_token()
    start = dt.datetime.now()
    os.chdir(destinationPath)
    with open("Main Log.txt", 'a') as f:
        f.write(f"\n Starting downloads \n -- {dt.datetime.now()} Set Authorization Token \n")
    for index, row in mediaDF.iterrows():
        location = row['location']
        PATH = os.path.join(destinationPath, location)
        if os.path.exists(PATH):
            for i in range(len(imageColumms)):
                # if there is actually a image file for that photo
                if isinstance(row[imageColumms[i]], str):
                    media_FileName = row[imageColumms[i]]
                    media_request = requests.get(f'https://five.epicollect.net/api/export/media/{PROJECT}?name={media_FileName}&format=entry_original&type=photo', headers = {'Authorization': f"Bearer {ACCESS_TOKEN}"})
                    
                    try:
                        with open(f'{PATH}/{imageColumms[i]}.jpg', 'wb') as f:
                            f.write(media_request.content)
                        with open(f'{PATH}/Download Log.txt', 'a') as f:
                            f.write(str(dt.datetime.now()) + f" -- Saved media file for {imageColumms[i]} \n")
                        time.sleep(2)
                    except:
                        with open(f'{PATH}/Download Log.txt', 'a') as f:
                            f.write(str(dt.datetime.now()) + f" -- Exception: media file for {location} \n")
                else:
                    with open(f'{PATH}/Download Log.txt', 'a') as f:
                        f.write(f"No picture taken for {imageColumms[i]} \n")
            with open("Main log.txt", 'a') as fi:
                fi.write(str(dt.datetime.now()) + f" -- Opened {PATH} \n")
            
        else:
            with open("Main Log.txt", 'a') as file:
                file.write(str(dt.datetime.now()) + f" -- Tried to open {PATH}: failed. \n")
        timeDifference = dt.datetime.now() - start
        if timeDifference.seconds >= 7000:
            # a couple minutes before the Token expires
            ACCESS_TOKEN = get_auth_token()
            with open("Main Log.txt", 'a') as fil:
                fil.write(str(dt.datetime.now()) + f" Reset Authorization Token \n")
            # Reset token timing
            start = dt.datetime.now()
    with open("Main Log.txt", 'a') as file:
        file.write(f"\n\nCompleted downloads, time: {dt.datetime.now()}")
    return


make_folders_per_location()
download_and_store_media()
