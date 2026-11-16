data "aws_caller_identity" "current" {}

resource "aws_kms_key" "secrets" {
  description             = "${var.project} – SSM SecureString encryption"
  deletion_window_in_days = 14
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Root account retains full admin (required or you lock yourself out).
      {
        Sid       = "RootAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      # Instance role can only decrypt, and only when the request originates
      # from SSM (kms:ViaService). Even if the role is compromised, it can't
      # use the key to encrypt arbitrary data or manage the key.
      {
        Sid       = "InstanceDecryptViaSSM"
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.instance.arn }
        Action    = "kms:Decrypt"
        Resource  = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.${var.region}.amazonaws.com"
          }
        }
      },
    ]
  })

  tags = { Name = "${var.project}-secrets" }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}
