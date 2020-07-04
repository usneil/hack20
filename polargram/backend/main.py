#API
from fastapi import FastAPI
import uvicorn
from pydantic import BaseModel

#Functions
from ImageProcessing.edits import ImageEdits
from ImageProcessing.DBConfig import ImgurConfigID, ImgurConfigSecret

#Misc
import uuid
import os

#Recommender
from Recommendation.recommender import Get_Data


class ImageModel(BaseModel):
    image_link : str

class UserModel(BaseModel):
    user_id : str

app = FastAPI()


@app.post('/polargramExposure')
async def exposures(image : ImageModel):
    #Image Library
    Image_Editor = ImageEdits(image.image_link, ImgurConfigID, ImgurConfigSecret)

    #Save the Image
    saveOrigImage = 'ImageProcessing/Images/' + str(uuid.uuid4()).replace('-', '') + '.' + image.image_link[-3:]

    print(saveOrigImage)

    #Crop and filter the image
    saveOrigImage = 'ImageProcessing/Images/' + str(uuid.uuid4()).replace('-', '') + '.png'
    Image_Editor.ImageDownload(saveOrigImage)
    Image_Editor.Filter(saveOrigImage)
    FilteredLink = Image_Editor.ToImgur(saveOrigImage)
    Response = {}
    for i in range(0, 5):
        Image_Editor.AdjustBrightness(saveOrigImage, saveOrigImage, i)
        BrightnessEdited = Image_Editor.ToImgur(saveOrigImage)
        y = 4 - i
        Response['image_' + str(y)] = BrightnessEdited

        
    
    print(Response)

    #Delete the file when we are done
    os.remove(saveOrigImage)

    return Response

@app.post('/polargramDiscover')
def feed_gen(user : UserModel):
    return Get_Data(user.user_id)
    

if __name__ == "__main__":
    uvicorn.run(app, host='127.0.0.1', port='2020')


