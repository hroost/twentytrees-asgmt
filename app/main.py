from typing import Union
from fastapi import FastAPI, File, UploadFile, HTTPException
from pydantic import BaseModel

import os
import requests
import json

import rasterio
import app.utils as utils

from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()

# directory to store uploaded files
upload_path = "./app/uploads"

def crop_and_save_img(img_name, crop):
    try:
        image,meta = utils.tif_to_image(img_name, crop=crop)

        print('Processing {}_slice_{}_{}.tif'.format(img_name, crop[0], crop[1]))

        with rasterio.open('{}_slice_{}_{}.tif'.format(img_name, crop[0], crop[1]), 'w', **meta) as dst:
            dst.write(image)
            return True
    except Exception as e:
        # TODO: Err 'Number of columns or rows must be non-negative' near the corners of the image
        print(f"Error: {e}")
        return False


@app.on_event("startup")
async def startup():
    # /metrics
    Instrumentator().instrument(app).expose(app)

@app.get("/")
def read_root():
    raise HTTPException(status_code=404, detail=f"Usage: POST /process, POST /analyze, GET /health")

@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/analyze_shared_crop")
async def process_shared_crop(image_path: str):

    try:
        res = utils.infer_image(file_path=f"./app/{image_path}", plot=False)

        # Converting the NumPy array into a Python list and then serialising it into a JSON object
        # https://stackoverflow.com/a/71104203
        return json.dumps(res.tolist())
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Something went wrong. Err: {e}")


@app.post("/analyze_uploaded_crop")
async def recive_file(file: UploadFile):

    # multipart/form-data
    # Usage: curl -X POST http://127.0.0.1:8080/analyze -F "file=@test.tif"
    # See also https://github.com/tiangolo/fastapi/issues/1653#issuecomment-734142838

    if file.content_type not in ["image/tiff"]:
        raise HTTPException(status_code=415, detail="Unsupported file type. Expected image/tiff.")

    try:
        # saving img to disk because lib expecting a local path
        with open(f"{upload_path}/{file.filename}", "wb") as buffer:
            content = await file.read()
            buffer.write(content)


        res = utils.infer_image(file_path=f"{upload_path}/{file.filename}", plot=False)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Something went wrong. Err: {e}")

    # clean up
    if os.path.exists(f"{upload_path}/{file.filename}"):
        os.remove(f"{upload_path}/{file.filename}")

    return json.dumps(res.tolist())


##
## WIP & test
##


@app.post("/upload")
async def fetch_image(url: str):
    # try to download image from url and save it to disk to upload_path
    # then validate that it is a tiff file
    try:
        r = requests.get(url, allow_redirects=True)
        # check content type if it is a tiff file
        if r.headers["Content-Type"] != "image/tiff":
            raise HTTPException(status_code=415, detail="Unsupported file type (expected image/tiff) or incorrect URL")
        
        # save file to disk with filename from url
        open(f"{upload_path}/{url.split('/')[-1]}", 'wb').write(r.content)
        
        return {"status": "success"}

    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=500, detail=f"Something went wrong. Err: {e}")

@app.post("/process")
async def process_image(image_path: str):
    # slading window over the tiff image by 512x512 pixels and saving each window to disk
    # then return the list of saved files
    try:
        # open tiff image
        with rasterio.open(f"{upload_path}/{image_path}") as src:
            # get image size
            height = src.height
            width = src.width

            slice_size = 512

            # loop through the image, slicing it into smaller pieces and saving each piece to disk
            for i in range(0, height, slice_size):
                for j in range(0, width, slice_size):
                    
                    ## crop = (5000,5000,512,512)
                    # print(f"slicing: {i+slice_size}x{j+slice_size}")
                    crop_and_save_img(f"{upload_path}/{image_path.split('/')[-1]}", (i+slice_size, j+slice_size, slice_size, slice_size))

        return {"status": "success"}
                

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Something went wrong. Err: {e}")

