# WireGuard server private key.
#
# Terraform creates the parameter shell only. The real value is pushed
# out-of-band (see README). Encrypted with the project CMK so only the
# instance role can decrypt, and only via SSM.
resource "aws_ssm_parameter" "wg_server_privkey" {
  name   = "/${var.project}/wireguard/server_private_key"
  type   = "SecureString"
  key_id = aws_kms_key.secrets.key_id
  value  = "PLACEHOLDER_SET_OUT_OF_BAND"

  tags = { Name = "${var.project}-wg-server-privkey" }

  lifecycle {
    ignore_changes = [value]
  }
}

# Fireworks AI inference API key.
#
# Same pattern as wireguard/server_private_key: Terraform creates the
# parameter shell, real value pushed out-of-band.  Instance role already
# has ssm:GetParameter on /hermes/* and kms:Decrypt on the CMK.
resource "aws_ssm_parameter" "fireworks_api_key" {
  name   = "/${var.project}/fireworks/api_key"
  type   = "SecureString"
  key_id = aws_kms_key.secrets.key_id
  value  = "PLACEHOLDER_SET_OUT_OF_BAND"

  tags = { Name = "${var.project}-fireworks-api-key" }

  lifecycle {
    ignore_changes = [value]
  }
}

# ── Phase 4 secrets ──────────────────────────────────────────────────
# Same pattern: Terraform creates parameter shells, real values pushed
# out-of-band.  Instance role already has ssm:GetParameter on /hermes/*
# and kms:Decrypt on the CMK.

resource "aws_ssm_parameter" "github_pat" {
  name   = "/${var.project}/mcp/github_pat"
  type   = "SecureString"
  key_id = aws_kms_key.secrets.key_id
  value  = "PLACEHOLDER_SET_OUT_OF_BAND"

  tags = { Name = "${var.project}-github-pat" }

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "slack_bot_token" {
  name   = "/${var.project}/mcp/slack_bot_token"
  type   = "SecureString"
  key_id = aws_kms_key.secrets.key_id
  value  = "PLACEHOLDER_SET_OUT_OF_BAND"

  tags = { Name = "${var.project}-slack-bot-token" }

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "slack_app_token" {
  name   = "/${var.project}/mcp/slack_app_token"
  type   = "SecureString"
  key_id = aws_kms_key.secrets.key_id
  value  = "PLACEHOLDER_SET_OUT_OF_BAND"

  tags = { Name = "${var.project}-slack-app-token" }

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "icloud_app_password" {
  name   = "/${var.project}/mcp/icloud_app_password"
  type   = "SecureString"
  key_id = aws_kms_key.secrets.key_id
  value  = "PLACEHOLDER_SET_OUT_OF_BAND"

  tags = { Name = "${var.project}-icloud-app-password" }

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "postman_api_key" {
  name   = "/${var.project}/mcp/postman_api_key"
  type   = "SecureString"
  key_id = aws_kms_key.secrets.key_id
  value  = "PLACEHOLDER_SET_OUT_OF_BAND"

  tags = { Name = "${var.project}-postman-api-key" }

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "plane_api_key" {
  name   = "/${var.project}/mcp/plane_api_key"
  type   = "SecureString"
  key_id = aws_kms_key.secrets.key_id
  value  = "PLACEHOLDER_SET_OUT_OF_BAND"
  tags   = { Name = "${var.project}-plane-api-key" }
  lifecycle { ignore_changes = [value] }
}

resource "aws_ssm_parameter" "plane_personal_api_key" {
  name   = "/${var.project}/mcp/plane_personal_api_key"
  type   = "SecureString"
  key_id = aws_kms_key.secrets.key_id
  value  = "PLACEHOLDER_SET_OUT_OF_BAND"
  tags   = { Name = "${var.project}-plane-personal-api-key" }
  lifecycle { ignore_changes = [value] }
}

# ── Tailscale ────────────────────────────────────────────────────────
# Reusable, non-expiring Tailscale auth key. Same pattern as the rest:
# Terraform creates the shell, the real value is pushed out-of-band. The
# instance reads it at boot to rejoin the tailnet after every spot
# replacement (no interactive login). Node identity is kept on /data.
resource "aws_ssm_parameter" "tailscale_auth_key" {
  name   = "/${var.project}/tailscale/auth_key"
  type   = "SecureString"
  key_id = aws_kms_key.secrets.key_id
  value  = "PLACEHOLDER_SET_OUT_OF_BAND"

  tags = { Name = "${var.project}-tailscale-auth-key" }

  lifecycle {
    ignore_changes = [value]
  }
}

