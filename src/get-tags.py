import boto3
import json
from decimal import Decimal

def lambda_handler(event, context):

    #Set env vars
    bucket = event['newBucket']
    key = event['newThumbnail']

    #Initialise Rekognition client and detect labels
    rek_client = boto3.client('rekognition')
    response = rek_client.detect_labels(Image={'S3Object': {'Bucket': bucket, 'Name': key}})

    #Add all tags that are greater than 80% confidence
    tags=[]
    for x in response['Labels']:
        conf = int(x['Confidence'])
        if conf > 80:
            tags.append(x['Name'])

    return {
        'statusCode': 200,
        'tags': json.dumps(tags),
        'exif': event['exif'],
        'pk': event['pk'],
        'sk': event['sk'],
        'newFilename': event['newFilename'],
        'newBucket': event['newBucket'],
        'newThumbnail': event['newThumbnail'],
        'originalFilename': event['originalFilename'],
        'originalBucket': event['originalBucket']
    }