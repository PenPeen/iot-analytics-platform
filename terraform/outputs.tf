# Terraform Outputs for IoT Platform

output "dynamodb_devices_table_name" {
  description = "Name of the DynamoDB devices table"
  value       = aws_dynamodb_table.devices.name
}

output "dynamodb_devices_table_arn" {
  description = "ARN of the DynamoDB devices table"
  value       = aws_dynamodb_table.devices.arn
}

output "dynamodb_sensor_data_table_name" {
  description = "Name of the DynamoDB sensor data table"
  value       = aws_dynamodb_table.sensor_data.name
}

output "dynamodb_sensor_data_table_arn" {
  description = "ARN of the DynamoDB sensor data table"
  value       = aws_dynamodb_table.sensor_data.arn
}

output "s3_data_archive_bucket_name" {
  description = "Name of the S3 data archive bucket"
  value       = aws_s3_bucket.iot_data_archive.bucket
}

output "s3_data_archive_bucket_arn" {
  description = "ARN of the S3 data archive bucket"
  value       = aws_s3_bucket.iot_data_archive.arn
}

output "sns_alerts_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = aws_sns_topic.iot_alerts.arn
}

output "sqs_sensor_data_processing_queue_url" {
  description = "URL of the SQS sensor data processing queue"
  value       = aws_sqs_queue.sensor_data_processing.url
}

output "sqs_sensor_data_processing_queue_arn" {
  description = "ARN of the SQS sensor data processing queue"
  value       = aws_sqs_queue.sensor_data_processing.arn
}

output "sqs_alert_notifications_queue_url" {
  description = "URL of the SQS alert notifications queue"
  value       = aws_sqs_queue.alert_notifications.url
}

output "sqs_alert_notifications_queue_arn" {
  description = "ARN of the SQS alert notifications queue"
  value       = aws_sqs_queue.alert_notifications.arn
}

output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    dynamodb_tables = {
      devices     = aws_dynamodb_table.devices.name
      sensor_data = aws_dynamodb_table.sensor_data.name
    }
    s3_buckets = {
      data_archive = aws_s3_bucket.iot_data_archive.bucket
    }
    sns_topics = {
      alerts = aws_sns_topic.iot_alerts.name
    }
    sqs_queues = {
      sensor_data_processing = aws_sqs_queue.sensor_data_processing.name
      alert_notifications    = aws_sqs_queue.alert_notifications.name
      dlq                   = aws_sqs_queue.sensor_data_dlq.name
    }
  }
}
