#Image Processing
from PIL import Image, ImageEnhance
import numpy as np
import cv2
from urllib.request import urlretrieve
from resizeimage.resizeimage import resize_crop, resize_cover

#Storage
from imgurpython import ImgurClient

#Misc
from random import randint

#Functions
class ImageEdits:
    def __init__(self, link, ImgurID, ImgurSecret):
        self.link = link #Makes link = to self.link
        try:
            self.ClientImgur = ImgurClient(ImgurID, ImgurSecret) #Instance of ImgurClient
            
        except:
            print('Incorrect Imgur IDs')

    def reorient_image(self, im):
        try:
            image_exif = im._getexif()
            image_orientation = image_exif[274]
            if image_orientation in (2,'2'):
                return im.transpose(Image.FLIP_LEFT_RIGHT)
            elif image_orientation in (3,'3'):
                return im.transpose(Image.ROTATE_180)
            elif image_orientation in (4,'4'):
                return im.transpose(Image.FLIP_TOP_BOTTOM)
            elif image_orientation in (5,'5'):
                return im.transpose(Image.ROTATE_90).transpose(Image.FLIP_TOP_BOTTOM)
            elif image_orientation in (6,'6'):
                return im.transpose(Image.ROTATE_270)
            elif image_orientation in (7,'7'):
                return im.transpose(Image.ROTATE_270).transpose(Image.FLIP_TOP_BOTTOM)
            elif image_orientation in (8,'8'):
                return im.transpose(Image.ROTATE_90)
            else:
                return im
        except (KeyError, AttributeError, TypeError, IndexError):
            return im

    def CropImage(self, image):
        'image : str : Path to the image you want to change'
        img = Image.open(image)
        img = self.reorient_image(img)
        img = resize_cover(img, [245, 255])
        img.save(image, img.format)

    def ImageDownload(self, fileDestination): #Download image from a url
        '''
        url : str : The URL of the image we are downloading
        fileDestination : str : the path where we want to save our files
        '''
        urlretrieve(self.link, str(fileDestination)) #Gets the image and saves it to thh File Destination we want

    def Filter(self, image): #Add A Filter
        'image : image_file : The original cropped image'
        #Init
        self.CropImage(image)
        self.CropImage('ImageProcessing/BlueOverlay.png')
        target_image = cv2.imread(image) #Read our Image, for CV2 Use
        overlay = cv2.imread('ImageProcessing/BlueOverlay.png')

        final = cv2.addWeighted(target_image,1 ,overlay,0.1,0)
        cv2.imwrite(image, final)

    def AdjustBrightness(self, image, savePath, brightness): #Adjust Brightness
        '''
        image : str : The path of original, cropped, and filtered image
        brightness : int : A integer value between 0 and 100
        '''
        brightness *= 1.5
        brightness = 1 + brightness #0 is the brightest, 100 is the least bright
        print(brightness)
        img = Image.open(image)
        enhancer = ImageEnhance.Brightness(img)
        enhanced_im = enhancer.enhance(brightness)
        enhanced_im.save(savePath)

    def ToImgur(self, path):
        Response = self.ClientImgur.upload_from_path(path, config=None, anon=True)
        return Response['link']

