resource "aws_security_group" "hermes" {
  name        = "${var.project}-sg"
  description = "Hermes agent: WireGuard only, all outbound"
  vpc_id      = aws_vpc.hermes.id

  # WireGuard handshake from anywhere. Noise IK crypto is the access gate.
  ingress {
    protocol    = "udp"
    from_port   = var.wireguard_listen_port
    to_port     = var.wireguard_listen_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound (for EC2 API calls, SSM, SQS, S3, Fireworks, etc.)
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-sg" }
}
