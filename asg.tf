resource "aws_autoscaling_group" "hermes" {
  name = "${var.project}-asg"
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [aws_subnet.public.id] # single AZ, pinned to EBS

  # Proactively replace instances flagged for rebalance and honor the
  # lifecycle hook during that replacement.
  capacity_rebalance = true
  health_check_type  = "EC2"

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.hermes.id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type = override.value
        }
      }
    }

    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0 # spot only, never on-demand
      spot_allocation_strategy                 = "capacity-optimized"
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-agent"
    propagate_at_launch = true
  }

  # Let a replacement fully spin up before the old one is torn down where
  # possible. min=max=1 means this is best-effort.
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
    }
  }
}

# Gives the on-instance consumer time to flush Hermes state before ASG
# terminates the instance (rebalance / scale-in). Completed by the Go daemon.
resource "aws_autoscaling_lifecycle_hook" "terminating" {
  name                   = "${var.project}-terminating"
  autoscaling_group_name = aws_autoscaling_group.hermes.name
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
  heartbeat_timeout      = 180
  default_result         = "CONTINUE"
}
