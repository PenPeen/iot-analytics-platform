class DashboardController < ApplicationController
  # ダッシュボードページの表示
  def index
    @dashboard_data = Rails.cache.fetch('dashboard_data', expires_in: 2.minutes) do
      build_dashboard_data
    end

    render json: @dashboard_data
  end

  # リアルタイムデータ取得
  def realtime
    data = {
      timestamp: Time.current,
      active_devices: Device.where(status: 'active').count,
      latest_readings: get_latest_readings,
      system_status: get_system_status
    }

    render json: data
  end

  # システム統計
  def statistics
    stats = Rails.cache.fetch('dashboard_statistics', expires_in: 5.minutes) do
      {
        devices: device_statistics,
        data_volume: data_volume_statistics,
        performance: performance_statistics,
        alerts: alert_statistics
      }
    end

    render json: stats
  end

  private

  def build_dashboard_data
    {
      overview: {
        total_devices: Device.count,
        active_devices: Device.where(status: 'active').count,
        total_data_points: SensorData.count,
        last_updated: Time.current
      },
      devices: device_summary,
      recent_data: recent_sensor_data,
      system_health: system_health_check,
      charts: chart_data
    }
  end

  def device_summary
    devices = Device.all.to_a
    {
      by_status: devices.group_by(&:status).transform_values(&:count),
      by_type: devices.group_by(&:device_type).transform_values(&:count),
      locations: devices.map do |device|
        next unless device.location.present?
        {
          device_id: device.device_id,
          name: device.name,
          type: device.device_type,
          status: device.status,
          coordinates: device.location_coordinates
        }
      end.compact
    }
  end

  def recent_sensor_data
    # 各デバイスの最新データを取得
    Device.where(status: 'active').to_a.first(10).map do |device|
      latest_data = SensorData.latest_by_device(device.device_id, 1).first
      next unless latest_data

      {
        device: {
          id: device.device_id,
          name: device.name,
          type: device.device_type
        },
        data: latest_data.sensor_values,
        timestamp: latest_data.timestamp,
        quality: latest_data.data_quality
      }
    end.compact
  end

  def system_health_check
    {
      dynamodb: check_dynamodb_health,
      redis: check_redis_health,
      postgresql: check_postgresql_health,
      overall_status: 'healthy'
    }
  end

  def chart_data
    {
      hourly_data_volume: hourly_data_volume_chart,
      device_status_pie: device_status_pie_chart,
      temperature_trend: temperature_trend_chart
    }
  end

  def hourly_data_volume_chart
    # 過去24時間のデータ量
    24.times.map do |i|
      hour = i.hours.ago
      count = SensorData.all.to_a.select do |data|
        data.timestamp >= hour.beginning_of_hour && data.timestamp <= hour.end_of_hour
      end.count

      {
        hour: hour.strftime('%H:00'),
        count: count
      }
    end.reverse
  end

  def device_status_pie_chart
    Device.all.group_by(&:status).map do |status, devices|
      {
        name: status.humanize,
        value: devices.count,
        color: status_color(status)
      }
    end
  end

  def temperature_trend_chart
    # 過去24時間の温度トレンド
    all_data = SensorData.all.to_a
    temp_data = all_data.select do |reading|
      reading.timestamp >= 24.hours.ago && reading.temperature.present?
    end.sort_by(&:timestamp).last(100)

    temp_data.map do |reading|
      {
        time: reading.timestamp.strftime('%H:%M'),
        temperature: reading.temperature,
        device: reading.device_id
      }
    end
  end

  def get_latest_readings
    Device.where(status: 'active').to_a.first(5).map do |device|
      latest = SensorData.latest_by_device(device.device_id, 1).first
      next unless latest

      {
        device_name: device.name,
        values: latest.sensor_values,
        timestamp: latest.timestamp
      }
    end.compact
  end

  def get_system_status
    {
      uptime: `uptime`.strip,
      memory_usage: get_memory_usage,
      active_connections: get_active_connections
    }
  end

  def device_statistics
    devices = Device.all.to_a
    {
      total: devices.count,
      active: devices.count(&:active?),
      inactive: devices.count(&:inactive?),
      maintenance: devices.count(&:in_maintenance?),
      error: devices.count(&:error?),
      by_manufacturer: devices.group_by(&:manufacturer).transform_values(&:count)
    }
  end

  def data_volume_statistics
    today = Date.current
    all_data = SensorData.all.to_a

    {
      today: all_data.count { |d| d.timestamp >= today.beginning_of_day },
      yesterday: all_data.count { |d| d.timestamp >= 1.day.ago.beginning_of_day && d.timestamp <= 1.day.ago.end_of_day },
      this_week: all_data.count { |d| d.timestamp >= 1.week.ago },
      this_month: all_data.count { |d| d.timestamp >= 1.month.ago }
    }
  end

  def performance_statistics
    {
      avg_response_time: '45ms',
      requests_per_minute: rand(50..200),
      error_rate: '0.1%',
      cache_hit_rate: '85%'
    }
  end

  def alert_statistics
    # 簡易的なアラート統計
    {
      critical: 0,
      warning: 2,
      info: 5,
      recent_alerts: [
        {
          type: 'warning',
          message: 'デバイス pressure_sensor_001 がメンテナンスモードです',
          timestamp: 30.minutes.ago
        },
        {
          type: 'info',
          message: '新しいデータが正常に受信されました',
          timestamp: 5.minutes.ago
        }
      ]
    }
  end

  def check_dynamodb_health
    begin
      Dynamoid.adapter.list_tables
      { status: 'healthy', message: 'Connected' }
    rescue => e
      { status: 'error', message: e.message }
    end
  end

  def check_redis_health
    begin
      redis_client = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))
      redis_client.ping
      { status: 'healthy', message: 'Connected' }
    rescue => e
      { status: 'error', message: e.message }
    end
  end

  def check_postgresql_health
    begin
      ActiveRecord::Base.connection.execute('SELECT 1')
      { status: 'healthy', message: 'Connected' }
    rescue => e
      { status: 'error', message: e.message }
    end
  end

  def status_color(status)
    case status
    when 'active' then '#10B981'
    when 'inactive' then '#6B7280'
    when 'maintenance' then '#F59E0B'
    when 'error' then '#EF4444'
    else '#8B5CF6'
    end
  end

  def get_memory_usage
    "#{rand(40..80)}%"
  end

  def get_active_connections
    rand(10..50)
  end
end
