#Create the state machine
resource "aws_sfn_state_machine" "state_machine" {
  name     = var.state_machine_name
  role_arn = aws_iam_role.state_machine.arn

  definition = <<EOF
{
  "Comment": "Copy image to archive bucket",
  "StartAt": "GenerateThumbnail",
  "States": {
    "GenerateThumbnail": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${aws_lambda_function.get_thumbnail.arn}:$LATEST"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 2,
          "BackoffRate": 2
        }
      ],
      "Next": "GetTags",
      "OutputPath": "$.Payload"
    },
    "GetTags": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${aws_lambda_function.get_tags.arn}:$LATEST"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 2,
          "BackoffRate": 2
        }
      ],
      "Next": "Parallel",
      "OutputPath": "$.Payload"
    },
    "Parallel": {
      "Type": "Parallel",
      "Next": "DeleteObject",
      "Branches": [
        {
          "StartAt": "StoreMetadata",
          "States": {
            "StoreMetadata": {
              "Type": "Task",
              "Resource": "arn:aws:states:::dynamodb:putItem",
              "Parameters": {
                "TableName": "${aws_dynamodb_table.index.id}",
                "Item": {
                  "PK": {
                    "S.$": "$.pk"
                  },
                  "SK": {
                    "S.$": "$.sk"
                  },
                  "filename": {
                    "S.$": "$.newFilename"
                  },
                  "bucket": {
                    "S.$": "$.newBucket"
                  },
                  "thumbnail": {
                    "S.$": "$.newThumbnail"
                  },
                  "tags": {
                    "S.$": "$.tags"
                  },
                  "exif": {
                    "S.$": "$.exif"
                  }
                }
              },
              "ResultPath": null,
              "End": true
            }
          }
        },
        {
          "StartAt": "ArchiveImage",
          "States": {
            "ArchiveImage": {
              "Type": "Task",
              "Parameters": {
                "Bucket.$": "$.newBucket",
                "CopySource.$": "States.Format('{}/{}', $.originalBucket, $.originalFilename)",
                "Key.$": "$.newFilename",
                "StorageClass": "GLACIER_IR"
              },
              "Resource": "arn:aws:states:::aws-sdk:s3:copyObject",
              "End": true
            }
          }
        }
      ],
      "ResultSelector": {
        "originalFilename.$": "$..originalFilename",
        "originalBucket.$": "$..originalBucket"
      }
    },
    "DeleteObject": {
      "Type": "Task",
      "End": true,
      "Parameters": {
        "Bucket.$": "$.originalBucket[0]",
        "Key.$": "$.originalFilename[0]"
      },
      "Resource": "arn:aws:states:::aws-sdk:s3:deleteObject"
    }
  }
}
EOF

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.state_machine.arn}:*"
    include_execution_data = true
    level                  = "ERROR"
  }
}

#Log group for the Step Function
resource "aws_cloudwatch_log_group" "state_machine" {
  name = "statemachines/${var.state_machine_name}"
}
