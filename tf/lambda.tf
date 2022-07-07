#Lambda function for the get_thumbnail task
resource "aws_lambda_function" "get_thumbnail" {
  filename         = "../src/get-thumbnail.zip"
  function_name    = "get-thumbnail"
  role             = aws_iam_role.get_thumbnail.arn
  handler          = "get-thumbnail.lambda_handler"
  source_code_hash = filebase64sha256("../src/get-thumbnail.zip")
  runtime          = "python3.9"
  layers           = [data.aws_lambda_layer_version.layer.arn]
  architectures    = ["x86_64"]
  timeout          = "120"
  memory_size      = "1024"

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.archive.id
    }
  }
}

#Lambda function for the get_tags task
resource "aws_lambda_function" "get_tags" {
  filename         = "../src/get-tags.zip"
  function_name    = "get-tags"
  role             = aws_iam_role.get_tags.arn
  handler          = "get-tags.lambda_handler"
  source_code_hash = filebase64sha256("../src/get-tags.zip")
  runtime          = "python3.9"
  architectures    = ["arm64"]
  timeout          = "120"
}