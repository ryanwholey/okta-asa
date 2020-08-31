data "aws_iam_policy_document" "trust_lambda" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "operate_lambda" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "operate_lambda" {
  name   = "${var.environment}-operate-lambda"
  policy = data.aws_iam_policy_document.operate_lambda.json
}

data "aws_iam_policy_document" "read_lambda_bucket" {
  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
    ]
    resources = [
      aws_s3_bucket.lambdas.arn,
      "${aws_s3_bucket.lambdas.arn}/*" 
    ]
  }
}

resource "aws_iam_policy" "read_lambda_bucket" {
  name   = "${var.environment}-read-lambda-bucket"
  policy = data.aws_iam_policy_document.read_lambda_bucket.json
}

resource "aws_iam_role" "unenroll_oktaasa_lambda" {
  name = "${var.environment}-oktaasa-unenroll-lambda"

  assume_role_policy = data.aws_iam_policy_document.trust_lambda.json
}

resource "aws_iam_role_policy_attachment" "operate_lambda" {
  role       = aws_iam_role.unenroll_oktaasa_lambda.name
  policy_arn = aws_iam_policy.operate_lambda.arn
}

resource "aws_iam_role_policy_attachment" "read_oktaasa_ssm" {
  role       = aws_iam_role.unenroll_oktaasa_lambda.name
  policy_arn = aws_iam_policy.read_oktaasa_ssm.arn
}

resource "aws_iam_role_policy_attachment" "unenroll_queue_read" {
  role       = aws_iam_role.unenroll_oktaasa_lambda.name
  policy_arn = aws_iam_policy.unenroll_queue_read.arn
}

resource "aws_iam_role_policy_attachment" "read_lambda_bucket" {
  role       = aws_iam_role.unenroll_oktaasa_lambda.name
  policy_arn = aws_iam_policy.read_lambda_bucket.arn
}

data "archive_file" "unenroll_oktaasa_server" {
  type        = "zip"
  output_path = "${path.module}/build/unenroll-oktaasa-server.zip"

  source {
    content       = templatefile("${path.module}/templates/unenroll-oktaasa-server.js", {
      environment = var.environment
    })
    filename = "exports.js"
  }
}

resource "aws_s3_bucket" "lambdas" {
  bucket = "${var.bucket_prefix}-lambdas"
  acl    = "private"

  versioning {
    enabled = true
  }
  force_destroy = true
}

resource "aws_s3_bucket_object" "unenroll_oktaasa_server" {
  bucket = aws_s3_bucket.lambdas.id
  key    = "unenroll-oktaasa-server.zip"
  source = data.archive_file.unenroll_oktaasa_server.output_path
  etag   = data.archive_file.unenroll_oktaasa_server.output_md5
}

resource "aws_lambda_function" "unenroll_oktaasa_function" {
  function_name = "unenroll-oktaasa-server"
  role          = aws_iam_role.unenroll_oktaasa_lambda.arn
  handler       = "exports.handler"

  s3_bucket          = aws_s3_bucket.lambdas.id
  s3_key             = aws_s3_bucket_object.unenroll_oktaasa_server.key
  s3_object_version  = aws_s3_bucket_object.unenroll_oktaasa_server.version_id 

  runtime = "nodejs12.x"
  publish = true
}

resource "aws_lambda_event_source_mapping" "trigger_from_queue" {
  batch_size        = 1
  event_source_arn  = aws_sqs_queue.unenrollment_queue.arn
  enabled           = true
  function_name     = aws_lambda_function.unenroll_oktaasa_function.arn
}

output "oktaasa_unenroll_lambda" {
  value = aws_iam_role.unenroll_oktaasa_lambda.arn
}
