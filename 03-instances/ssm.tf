
resource "aws_kms_key" "oktaasa" {
  description  = "KMS key for encrypting and decrypting the Okta ASA credentials in SSM"
}

resource "aws_ssm_parameter" "oktaasa_team" {
  name        = "/oktaasa/${var.environment}/oktaasa-team"
  description = "Okta ASA team"
  type        = "SecureString"
  key_id      = aws_kms_key.oktaasa.id
  value       = var.oktaasa_team
}

resource "aws_ssm_parameter" "oktaasa_key" {
  name        = "/oktaasa/${var.environment}/oktaasa-key"
  description = "Okta ASA machine user key ID"
  type        = "SecureString"
  key_id      = aws_kms_key.oktaasa.id
  value       = var.oktaasa_key
}

resource "aws_ssm_parameter" "oktaasa_key_secret" {
  name        = "/oktaasa/${var.environment}/oktaasa-key-secret"
  description = "Okta ASA machine user key secret"
  type        = "SecureString"
  key_id      = aws_kms_key.oktaasa.id
  value       = var.oktaasa_key_secret
}

data "aws_iam_policy_document" "read_oktaasa_ssm" {
  statement {
    actions = ["ssm:DescribeParameters"]
    resources = ["*"]
  }
  statement {
    actions = ["ssm:GetParameters"]
    resources = [
      aws_ssm_parameter.oktaasa_team.arn,
      aws_ssm_parameter.oktaasa_key.arn,
      aws_ssm_parameter.oktaasa_key_secret.arn,
    ]
  }
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
    ]
    resources = [aws_kms_key.oktaasa.arn]
  }
}

resource "aws_iam_policy" "read_oktaasa_ssm" {
  name   = "${var.environment}-read-oktaasa-ssm"
  policy = data.aws_iam_policy_document.read_oktaasa_ssm.json
}
