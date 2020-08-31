
resource "aws_sqs_queue" "unenrollment_queue" {
  name = "okta-asa-unenrollment-queue"
}

data "aws_iam_policy_document" "unenroll_queue_read" {
  statement {
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage"
    ]
    resources = [
      aws_sqs_queue.unenrollment_queue.arn
    ]
  }
}

resource "aws_iam_policy" "unenroll_queue_read" {
  name   = "${var.environment}-unenroll-queue-read"
  policy = data.aws_iam_policy_document.unenroll_queue_read.json
}

data "aws_iam_policy_document" "lifecycle_publish_sqs" {
  statement {
    actions = [
      "sqs:Send*",
      "sqs:Get*",
      "sns:Publish"
    ]
    resources = [
      aws_sqs_queue.unenrollment_queue.arn
    ]
  }
}

resource "aws_iam_policy" "unenroll_write" {
  name        = "${var.environment}-unenroll-write"
  policy = data.aws_iam_policy_document.lifecycle_publish_sqs.json
}
