resource "aws_sqs_queue" "spot_interruption" {
  name                      = "${var.project}-spot-interruption-events"
  message_retention_seconds = 3600
  receive_wait_time_seconds = 20
  visibility_timeout_seconds = 30

  tags = { Name = "${var.project}-spot-interruption-events" }
}

resource "aws_sqs_queue_policy" "spot_interruption" {
  queue_url = aws_sqs_queue.spot_interruption.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.spot_interruption.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = [
              aws_cloudwatch_event_rule.spot_interruption_warning.arn,
              aws_cloudwatch_event_rule.spot_rebalance_recommendation.arn,
            ]
          }
        }
      }
    ]
  })
}

# Spot Instance Interruption Warning (2-minute notice)
resource "aws_cloudwatch_event_rule" "spot_interruption_warning" {
  name        = "${var.project}-spot-interruption-warning"
  description = "EC2 Spot Instance Interruption Warning"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })
}

resource "aws_cloudwatch_event_target" "spot_interruption_warning" {
  rule      = aws_cloudwatch_event_rule.spot_interruption_warning.name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.spot_interruption.arn
}

# EC2 Instance Rebalance Recommendation
resource "aws_cloudwatch_event_rule" "spot_rebalance_recommendation" {
  name        = "${var.project}-spot-rebalance-recommendation"
  description = "EC2 Instance Rebalance Recommendation"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance Rebalance Recommendation"]
  })
}

resource "aws_cloudwatch_event_target" "spot_rebalance_recommendation" {
  rule      = aws_cloudwatch_event_rule.spot_rebalance_recommendation.name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.spot_interruption.arn
}
