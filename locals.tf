locals {
  user_data_header = templatefile("${path.module}/templates/user_data_header.tftpl", {
    DATA_VOLUME_NAME      = aws_ebs_volume.data.tags["Name"]
    EIP_ALLOC_ID          = aws_eip.hermes.id
    WG_LISTEN_PORT        = var.wireguard_listen_port
    WG_CLIENT_PUBKEY      = var.wireguard_client_pubkey
    WG_SERVER_PRIVKEY_SSM = aws_ssm_parameter.wg_server_privkey.name
    SPOT_QUEUE_URL        = aws_sqs_queue.spot_interruption.url
    ASG_NAME              = "${var.project}-asg"

    # Phase 2
    FIREWORKS_API_KEY_SSM      = aws_ssm_parameter.fireworks_api_key.name
    HERMES_DASHBOARD_PASSWORD  = var.hermes_dashboard_password
    GITHUB_PAT_SSM             = aws_ssm_parameter.github_pat.name
    SLACK_BOT_TOKEN_SSM        = aws_ssm_parameter.slack_bot_token.name
    SLACK_APP_TOKEN_SSM        = aws_ssm_parameter.slack_app_token.name
    ICLOUD_APP_PASSWORD_SSM    = aws_ssm_parameter.icloud_app_password.name
    POSTMAN_API_KEY_SSM        = aws_ssm_parameter.postman_api_key.name
    PLANE_API_KEY_SSM          = aws_ssm_parameter.plane_api_key.name
    PLANE_PERSONAL_API_KEY_SSM = aws_ssm_parameter.plane_personal_api_key.name

    # Tailscale
    TAILSCALE_AUTH_KEY_SSM = aws_ssm_parameter.tailscale_auth_key.name
    TAILSCALE_HOSTNAME     = var.tailscale_hostname
  })

  user_data_body = file("${path.module}/templates/user_data_body.sh")

  # Combine header (env exports) + body (boot logic), then gzip + base64 for cloud-init
  user_data = base64gzip(<<-EOT
${trimspace(local.user_data_header)}

${trimspace(local.user_data_body)}
EOT
  )
}
