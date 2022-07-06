#Eventbridge rule 
resource "aws_cloudwatch_event_rule" "s3" {
  name        = "${var.project_name}-uploads"
  description = "Uploads to the RAW archiver upload bucket"

  event_pattern = <<EOF
{
  "source": ["aws.s3"],
  "detail-type": ["Object Created"],
  "detail": {
    "bucket": {
      "name": ["${aws_s3_bucket.uploads.id}"]
    }
  }
}
EOF
}

#Eventbridge target
resource "aws_cloudwatch_event_target" "s3" {
  rule      = aws_cloudwatch_event_rule.s3.name
  target_id = "${var.project_name}-state-machine"
  arn       = aws_sfn_state_machine.state_machine.arn
  role_arn  = aws_iam_role.step_function.arn
}