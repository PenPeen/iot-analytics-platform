# DynamoDB configuration for LocalStack
Dynamoid.configure do |config|
  # LocalStack endpoint
  if Rails.env.development? || Rails.env.test?
    config.endpoint = ENV.fetch('AWS_ENDPOINT', 'http://localhost:4566')
    config.region = ENV.fetch('AWS_REGION', 'ap-northeast-1')
    config.access_key = ENV.fetch('AWS_ACCESS_KEY_ID', 'test')
    config.secret_key = ENV.fetch('AWS_SECRET_ACCESS_KEY', 'test')
  else
    # Production settings (use IAM roles or environment variables)
    config.region = ENV.fetch('AWS_REGION', 'ap-northeast-1')
  end

  # Table settings
  config.namespace = "iot_platform_#{Rails.env}"
  config.warn_on_scan = true
  config.timestamps = true

  # Read/Write capacity for tables
  config.read_capacity = 5
  config.write_capacity = 5

  # Sync all tables on startup in development
  config.sync_retry_max_times = 60
  config.sync_retry_wait_seconds = 2

  # Disable backoff for now to avoid configuration issues
  config.backoff = false
end

# Initialize DynamoDB tables in development
if Rails.env.development?
  Rails.application.config.after_initialize do
    begin
      # Wait for LocalStack to be ready
      sleep 2

      # Create tables if they don't exist
      Dynamoid.adapter.list_tables.each do |table_name|
        Rails.logger.info "DynamoDB table exists: #{table_name}"
      end

      Rails.logger.info "DynamoDB connection established"
    rescue => e
      Rails.logger.warn "DynamoDB connection failed: #{e.message}"
    end
  end
end
