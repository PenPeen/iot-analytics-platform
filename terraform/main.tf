# IoTデータ収集・分析プラットフォーム用 Terraform設定 (LocalStack)

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# LocalStack Provider設定
provider "aws" {
  region                      = "ap-northeast-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style          = true

  endpoints {
    dynamodb = "http://localhost:4566"
    s3       = "http://localhost:4566"
    sns      = "http://localhost:4566"
    sqs      = "http://localhost:4566"
  }
}

# DynamoDB テーブル: デバイス情報
resource "aws_dynamodb_table" "devices" {
  name           = "iot_platform_development_devices"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "device_id"

  attribute {
    name = "device_id"
    type = "S"
  }

  # デバイスタイプ別検索用GSI
  global_secondary_index {
    name            = "device_type_index"
    hash_key        = "device_type"
    projection_type = "ALL"
  }

  attribute {
    name = "device_type"
    type = "S"
  }

  # ステータス別検索用GSI
  global_secondary_index {
    name            = "status_index"
    hash_key        = "status"
    projection_type = "ALL"
  }

  attribute {
    name = "status"
    type = "S"
  }

  tags = {
    Name        = "IoT Platform Devices"
    Environment = "development"
    Purpose     = "device_management"
  }
}

# DynamoDB テーブル: センサーデータ（時系列）
resource "aws_dynamodb_table" "sensor_data" {
  name           = "iot_platform_development_sensor_data"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "partition_key"
  range_key      = "sort_key"

  attribute {
    name = "partition_key"
    type = "S"
  }

  attribute {
    name = "sort_key"
    type = "S"
  }

  # デバイス別検索用GSI
  global_secondary_index {
    name            = "device_timestamp_index"
    hash_key        = "device_id"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  # TTL設定（古いデータの自動削除）
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name        = "IoT Platform Sensor Data"
    Environment = "development"
    Purpose     = "time_series_data"
  }
}

# S3バケット: データバックアップ・アーカイブ用
resource "aws_s3_bucket" "iot_data_archive" {
  bucket = "iot-platform-data-archive"

  tags = {
    Name        = "IoT Platform Data Archive"
    Environment = "development"
    Purpose     = "data_backup"
  }
}

# S3 versioning設定
resource "aws_s3_bucket_versioning" "iot_data_archive_versioning" {
  bucket = aws_s3_bucket.iot_data_archive.id
  versioning_configuration {
    status = "Enabled"
  }
}

# SNS トピック: アラート通知用
resource "aws_sns_topic" "iot_alerts" {
  name = "iot-platform-alerts"

  tags = {
    Name        = "IoT Platform Alerts"
    Environment = "development"
    Purpose     = "alert_notifications"
  }
}

# SQS キュー: センサーデータ処理用
resource "aws_sqs_queue" "sensor_data_processing" {
  name                      = "iot-sensor-data-processing"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.sensor_data_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "IoT Sensor Data Processing Queue"
    Environment = "development"
    Purpose     = "data_processing"
  }
}

# SQS DLQ: 処理失敗データ用
resource "aws_sqs_queue" "sensor_data_dlq" {
  name                      = "iot-sensor-data-processing-dlq"
  message_retention_seconds = 1209600

  tags = {
    Name        = "IoT Sensor Data Processing DLQ"
    Environment = "development"
    Purpose     = "failed_message_handling"
  }
}

# SQS キュー: アラート通知用
resource "aws_sqs_queue" "alert_notifications" {
  name                      = "iot-alert-notifications"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600
  receive_wait_time_seconds = 10

  tags = {
    Name        = "IoT Alert Notifications Queue"
    Environment = "development"
    Purpose     = "alert_processing"
  }
}

# SNS-SQS連携: アラート通知
resource "aws_sns_topic_subscription" "alert_to_sqs" {
  topic_arn = aws_sns_topic.iot_alerts.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.alert_notifications.arn
}

# SQSポリシー: SNSからのメッセージ受信許可
resource "aws_sqs_queue_policy" "alert_notifications_policy" {
  queue_url = aws_sqs_queue.alert_notifications.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.alert_notifications.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.iot_alerts.arn
          }
        }
      }
    ]
  })
}
