resource "aws_ebs_volume" "data" {
  availability_zone = var.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true
  iops              = 3000
  throughput        = 125
  snapshot_id       = var.data_snapshot_id

  tags = { Name = "${var.project}-data" }

  lifecycle {
    prevent_destroy = true
    # snapshot_id only matters at creation; clearing it later must not
    # force a replacement.
    ignore_changes = [snapshot_id]
  }
}

resource "aws_eip" "hermes" {
  domain = "vpc"

  tags = { Name = "${var.project}-eip" }

  depends_on = [aws_internet_gateway.hermes]
}

resource "aws_key_pair" "ssh" {
  key_name   = "${var.project}-ssh"
  public_key = var.ssh_public_key

  tags = { Name = "${var.project}-ssh-key" }
}
