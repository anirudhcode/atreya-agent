data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "hermes" {
  name_prefix   = "${var.project}-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_types[0] # used as default; ASG overrides with mixed policy

  iam_instance_profile {
    arn = aws_iam_instance_profile.instance.arn
  }

  vpc_security_group_ids = [aws_security_group.hermes.id]

  key_name = aws_key_pair.ssh.key_name

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 enforced
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  user_data = local.user_data

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project}-instance"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "${var.project}-root"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
