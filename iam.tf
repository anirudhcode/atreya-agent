resource "aws_iam_role" "instance" {
  name = "${var.project}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = { Name = "${var.project}-instance-role" }
}

resource "aws_iam_role_policy" "instance" {
  name = "${var.project}-instance-policy"
  role = aws_iam_role.instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Volume attachment (first boot: attach /data, find device by serial)
      {
        Effect = "Allow"
        Action = [
          "ec2:AttachVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeInstances",
        ]
        Resource = "*"
      },
      # EIP association (stable endpoint for WireGuard)
      {
        Effect = "Allow"
        Action = [
          "ec2:AssociateAddress",
          "ec2:DescribeAddresses",
        ]
        Resource = "*"
      },
      # SSM GetParameter: WireGuard private key (and later, Fireworks API key, MCP creds)
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
        ]
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project}/*"
      },
      # KMS Decrypt for SSM (restricted by key policy to ViaService=ssm)
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
        ]
        Resource = aws_kms_key.secrets.arn
      },
      # Spot interruption: SQS queue polling
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ]
        Resource = aws_sqs_queue.spot_interruption.arn
      },
      # ASG lifecycle hook completion
      {
        Effect = "Allow"
        Action = [
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:RecordLifecycleActionHeartbeat",
          "autoscaling:DescribeAutoScalingInstances",
        ]
        Resource = "*"
      },
    ]
  })
}

# Break-glass: SSM Session Manager (if WireGuard is down)
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.project}-instance-profile"
  role = aws_iam_role.instance.name
}
