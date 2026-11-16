output "wireguard_endpoint" {
  description = "WireGuard endpoint for Mac config (EIP:port)"
  value       = "${aws_eip.hermes.public_ip}:${var.wireguard_listen_port}"
}

output "eip" {
  description = "Elastic IP assigned to the instance"
  value       = aws_eip.hermes.public_ip
}

output "asg_name" {
  description = "ASG name (use for instance-refresh, terminate-instance-in-auto-scaling-group)"
  value       = aws_autoscaling_group.hermes.name
}

output "data_volume_id" {
  description = "Persistent /data EBS volume ID (prevent_destroy enabled)"
  value       = aws_ebs_volume.data.id
}

output "data_volume_size_gb" {
  description = "Persistent /data volume size"
  value       = aws_ebs_volume.data.size
}

output "spot_queue_url" {
  description = "SQS queue URL for spot interruption events"
  value       = aws_sqs_queue.spot_interruption.url
}

output "spot_queue_arn" {
  description = "SQS queue ARN for spot interruption events"
  value       = aws_sqs_queue.spot_interruption.arn
}

output "kms_key_id" {
  description = "KMS CMK ID for secrets"
  value       = aws_kms_key.secrets.key_id
}

output "kms_key_arn" {
  description = "KMS CMK ARN for secrets"
  value       = aws_kms_key.secrets.arn
}

output "instance_role_arn" {
  description = "Instance IAM role ARN"
  value       = aws_iam_role.instance.arn
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.hermes.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.hermes.id
}

output "subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}
