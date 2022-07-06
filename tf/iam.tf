#IAM Role for the get_thumbnail lambda function
resource "aws_iam_role" "get_thumbnail" {
  name = "${var.project_name}-get-thumbnail"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"]

  inline_policy {
    name   = "s3"
    policy = data.aws_iam_policy_document.thumbnail_s3.json
  }
}

data "aws_iam_policy_document" "thumbnail_s3" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = [aws_s3_bucket.uploads.arn, "${aws_s3_bucket.uploads.arn}/*", aws_s3_bucket.archive.arn, "${aws_s3_bucket.archive.arn}/*"]
  }
}

#IAM Role for the get_tags lambda function
resource "aws_iam_role" "get_tags" {
  name = "${var.project_name}-get-tags"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"]

  inline_policy {
    name   = "s3"
    policy = data.aws_iam_policy_document.tags_s3.json
  }

  inline_policy {
    name   = "rek"
    policy = data.aws_iam_policy_document.tags_rek.json
  }
}

data "aws_iam_policy_document" "tags_s3" {
  statement {
    actions   = ["s3:GetObject"]
    resources = [aws_s3_bucket.archive.arn, "${aws_s3_bucket.archive.arn}/*"]
  }
}

data "aws_iam_policy_document" "tags_rek" {
  statement {
    actions   = ["rekognition:DetectLabels"]
    resources = ["*"]
  }
}

#IAM Role for the state machine
resource "aws_iam_role" "state_machine" {
  name = "${var.project_name}-state-machine-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  inline_policy {
    name   = "logs"
    policy = data.aws_iam_policy_document.logs.json
  }

  inline_policy {
    name   = "lambda"
    policy = data.aws_iam_policy_document.lambda.json
  }
 
  inline_policy {
    name   = "s3"
    policy = data.aws_iam_policy_document.s3.json
  }

  inline_policy {
    name   = "dynamodb"
    policy = data.aws_iam_policy_document.dynamodb.json
  }
}

data "aws_iam_policy_document" "logs" {
  statement {
    actions   = ["logs:CreateLogDelivery", "logs:GetLogDelivery", "logs:UpdateLogDelivery", "logs:DeleteLogDelivery", "logs:ListLogDeliveries", "logs:PutResourcePolicy", "logs:DescribeResourcePolicies", "logs:DescribeLogGroups"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = ["${aws_lambda_function.get_thumbnail.arn}:*", "${aws_lambda_function.get_tags.arn}:*"]
  }
}

data "aws_iam_policy_document" "s3" {
  statement {
    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = [aws_s3_bucket.uploads.arn, "${aws_s3_bucket.uploads.arn}/*", aws_s3_bucket.archive.arn, "${aws_s3_bucket.archive.arn}/*"]
  }
}

data "aws_iam_policy_document" "dynamodb" {
  statement {
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.index.arn]
  }
}

#IAM role for EventBridge to invoke Step Function
resource "aws_iam_role" "step_function" {
  name = "${var.project_name}-eventbridge-step-function"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  inline_policy {
    name   = "invoke_step_function"
    policy = data.aws_iam_policy_document.step_function.json
  }
}

data "aws_iam_policy_document" "step_function" {
  statement {
    actions   = ["states:StartExecution"]
    resources = [aws_sfn_state_machine.state_machine.arn]
  }
}