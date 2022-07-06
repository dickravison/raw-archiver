# raw-archiver
This project takes Nikon RAW .NEF files from an upload bucket and:

- Generates a thumbnail
- Extracts EXIF data
- Generates tags using AWS Rekognition
- Indexes the image and metadata in DynamoDB
- Stores the uploaded RAW image in Glacier Instant Retrieval

## To Do
- Finish README
- Speed up Lambda functions
- Refactor IaC
- Refactor Python code
