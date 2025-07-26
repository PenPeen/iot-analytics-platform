# S3インポート用設定

resource "aws_s3_bucket" "test_import_bucket" {
  bucket              = "test-import-bucket"
  bucket_prefix       = null
  force_destroy       = null
  object_lock_enabled = false
  tags = {
    Environment = "development"
    Name        = "Test Import Bucket"
    Purpose     = "import_test"
  }
  tags_all = {
    Environment = "development"
    Name        = "Test Import Bucket"
    Purpose     = "import_test"
  }
}
