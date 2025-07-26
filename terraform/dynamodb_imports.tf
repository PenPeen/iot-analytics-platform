# DynamoDBインポート用設定

resource "aws_dynamodb_table" "test_import_table" {
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = false
  hash_key                    = "id"
  name                        = "test-import-table"
  range_key                   = null
  read_capacity               = 0
  restore_date_time           = null
  restore_source_name         = null
  restore_source_table_arn    = null
  restore_to_latest_time      = null
  stream_enabled              = false
  stream_view_type            = null
  table_class                 = "STANDARD"
  tags = {
    Environment = "development"
    Name        = "Test Import Table"
    Purpose     = "import_test"
  }
  tags_all = {
    Environment = "development"
    Name        = "Test Import Table"
    Purpose     = "import_test"
  }
  write_capacity = 0

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = false
    # recovery_period_in_days = 0 # この行を削除してエラーを修正
  }

  ttl {
    attribute_name = null
    enabled        = false
  }
}
