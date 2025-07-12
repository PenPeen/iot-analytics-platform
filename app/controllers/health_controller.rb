class HealthController < ApplicationController
  # システムヘルスチェック
  def index
    health_status = {
      status: 'healthy',
      timestamp: Time.current,
      services: check_services,
      version: '1.0.0',
      environment: Rails.env
    }

    # いずれかのサービスが異常な場合は全体のステータスを unhealthy に
    if health_status[:services].any? { |_, service| service[:status] != 'healthy' }
      health_status[:status] = 'unhealthy'
    end

    status_code = health_status[:status] == 'healthy' ? :ok : :service_unavailable
    render json: health_status, status: status_code
  end

  private

  def check_services
    {
      dynamodb: check_dynamodb,
      redis: check_redis,
      postgresql: check_postgresql
    }
  end

  def check_dynamodb
    begin
      # DynamoDBの接続テスト
      Dynamoid.adapter.list_tables
      {
        status: 'healthy',
        message: 'DynamoDB connection successful',
        response_time: measure_response_time { Dynamoid.adapter.list_tables }
      }
    rescue => e
      {
        status: 'unhealthy',
        message: "DynamoDB connection failed: #{e.message}",
        error: e.class.name
      }
    end
  end

  def check_redis
    begin
      # Redisの接続テスト
      redis_client = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))
      redis_client.ping
      {
        status: 'healthy',
        message: 'Redis connection successful',
        response_time: measure_response_time { redis_client.ping }
      }
    rescue => e
      {
        status: 'unhealthy',
        message: "Redis connection failed: #{e.message}",
        error: e.class.name
      }
    end
  end

  def check_postgresql
    begin
      # PostgreSQLの接続テスト
      ActiveRecord::Base.connection.execute('SELECT 1')
      {
        status: 'healthy',
        message: 'PostgreSQL connection successful',
        response_time: measure_response_time { ActiveRecord::Base.connection.execute('SELECT 1') }
      }
    rescue => e
      {
        status: 'unhealthy',
        message: "PostgreSQL connection failed: #{e.message}",
        error: e.class.name
      }
    end
  end

  def measure_response_time
    start_time = Time.current
    yield
    ((Time.current - start_time) * 1000).round(2)
  end
end
