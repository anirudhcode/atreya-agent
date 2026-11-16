variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Name prefix for all resources"
  type        = string
  default     = "hermes"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.20.1.0/24"
}

variable "availability_zone" {
  description = "Single AZ, pinned to the EBS data volume. ASG launches only here. Changing it requires recreating /data from a snapshot (see README)."
  type        = string
  default     = "ap-south-1b" # aps1-az3; ap-south-1a (aps1-az1) had poor spot placement scores
}

variable "data_snapshot_id" {
  description = "Snapshot to restore the /data volume from when it is (re)created. Null for an empty volume."
  type        = string
  default     = null
}

variable "instance_types" {
  description = "Graviton ARM types for the mixed-instances policy. All 2 vCPU / >= 4 GiB."
  type        = list(string)
  default = [
    "t4g.medium",
    "t4g.large",
    "c6g.large",
    "c7g.large",
    "c8g.large",
    "m6g.large",
    "m7g.large",
    "m8g.large",
    "r6g.large",
    "r7g.large",
    "r8g.large",
  ]
}

variable "root_volume_size" {
  description = "Root (ephemeral) volume size in GB"
  type        = number
  default     = 10
}

variable "data_volume_size" {
  description = "Persistent /data volume size in GB"
  type        = number
  default     = 20
}

variable "ssh_public_key" {
  description = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDsuO/Nf+FkJxhK2LSRRRuolcq53db0oPhxg/JE4JEKo anirudhcode@icloud.com"
  type        = string
}

variable "wireguard_client_pubkey" {
  description = "kyJIepr4Z9/5JQh3krcxvqRdM6IBgChrhz3XRXwUYXc="
  type        = string
}

variable "wireguard_listen_port" {
  type    = number
  default = 51820
}

variable "hermes_dashboard_password" {
  description = "Basic-auth password for the Hermes web dashboard (alphanumeric, no shell special chars). Dashboard is reachable only via WireGuard."
  type        = string
  sensitive   = true
}

variable "tailscale_hostname" {
  description = "Tailnet hostname for this box (its MagicDNS name, e.g. hermes-box)."
  type        = string
  default     = "hermes-box"
}
