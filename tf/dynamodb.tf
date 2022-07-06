#DynamoDB Table
resource "aws_dynamodb_table" "index" {
  name         = "${var.project_name}-index"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "filename"

  attribute {
    name = "filename"
    type = "S"
  }

}