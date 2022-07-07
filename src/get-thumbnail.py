import json
import uuid
import boto3
import rawpy
import imageio
import os
from PIL import Image, TiffImagePlugin, ExifTags
from datetime import datetime, timedelta

def lambda_handler(event, context):

   #Set env vars
   uploadBucket=event['detail']['bucket']['name']
   uploadObject=event['detail']['object']['key']
   newBucket=os.environ['S3_BUCKET']
   tmpfile='/tmp/image.NEF'

   #Initialise S3 client and download RAW image
   s3 = boto3.client('s3')
   s3.download_file(uploadBucket, uploadObject, tmpfile)

   #Create unique filename
   filename = str(uuid.uuid1())
   #A local file for local people
   localfile = '/tmp/' + filename + '.jpeg'

   #Get thumbnail from RAW image
   with rawpy.imread(tmpfile) as raw:
      thumb = raw.extract_thumb()
   if thumb.format == rawpy.ThumbFormat.JPEG:
      with open(localfile, 'wb') as f:
         f.write(thumb.data)
   elif thumb.format == rawpy.ThumbFormat.BITMAP:
      imageio.imsave(localfile, thumb.data)

   #Upload thumbnail to S3
   s3.upload_file(localfile, newBucket, 'thumbnails/' + filename + '.jpeg')

   #Get EXIF data
   processedimage = Image.open(localfile)
   exif = {}
   for k, v in processedimage._getexif().items():
      if k in ExifTags.TAGS:
         if isinstance(v, TiffImagePlugin.IFDRational):
            v = float(v)
         elif isinstance(v, tuple):
            v = tuple(float(t) if isinstance(t, TiffImagePlugin.IFDRational) else t for t in v)
         elif isinstance(v, bytes):
            v = v.decode(errors="replace")
         exif[ExifTags.TAGS[k]] = v

   #Generate sort key (date picture was taken + uuid)
   date=exif['DateTime']
   convertdate = datetime.strptime(date,"%Y:%m:%d %H:%M:%S")
   sortkey = datetime.strftime(convertdate,"%Y#%m#%d#%H#%M#%S#")

   return {
        'statusCode': 200,
        'newFilename': filename + '.NEF',
        'newBucket': newBucket,
        'newThumbnail': 'thumbnails/' + filename + '.jpeg',
        'originalFilename': event['detail']['object']['key'],
        'exif': json.dumps(exif),
        'pk': 'IMAGE#NEF',
        'sk': sortkey + filename,
        'originalBucket': event['detail']['bucket']['name']
   }