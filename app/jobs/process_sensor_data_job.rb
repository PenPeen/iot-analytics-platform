class ProcessSensorDataJob
  include Sidekiq::Job

  sidekiq_options retry: 3, queue: 'sensor_data'

  def perform(device_id, sensor_data_id)
    logger.info "Processing sensor data for device #{device_id}, data ID: #{sensor_data_id}"

    # センサーデータを取得
    sensor_data = SensorData.find(sensor_data_id)
    device = Device.find(device_id)

    # データ品質チェック
    check_data_quality(sensor_data)

    # アラート判定
    check_alerts(device, sensor_data)

    # 統計データ更新
    update_statistics(device_id, sensor_data)

    # 外部システムへの通知（必要に応じて）
    notify_external_systems(device, sensor_data) if should_notify?(sensor_data)

    logger.info "Sensor data processing completed for device #{device_id}"

  rescue Dynamoid::Errors::RecordNotFound => e
    logger.error "Record not found: #{e.message}"
    # リトライしない
  rescue => e
    logger.error "Error processing sensor data: #{e.message}"
    logger.error e.backtrace.join("\n")
    raise # Sidekiqでリトライさせる
  end

  private

  def check_data_quality(sensor_data)
    # データ品質の評価
    quality_score = calculate_quality_score(sensor_data)

    if quality_score < 60
      sensor_data.update(data_quality: 'poor')
      logger.warn "Poor data quality detected for sensor data #{sensor_data.id}"
    elsif quality_score < 80
      sensor_data.update(data_quality: 'fair')
    else
      sensor_data.update(data_quality: 'good')
    end
  end

  def calculate_quality_score(sensor_data)
    score = 100

    # 温度の妥当性チェック
    if sensor_data.temperature.present?
      if sensor_data.temperature < -40 || sensor_data.temperature > 60
        score -= 30
      end
    end

    # 湿度の妥当性チェック
    if sensor_data.humidity.present?
      if sensor_data.humidity < 0 || sensor_data.humidity > 100
        score -= 30
      end
    end

    # バッテリーレベルチェック
    if sensor_data.battery_level.present? && sensor_data.battery_level < 20
      score -= 10
    end

    # 信号強度チェック
    if sensor_data.signal_strength.present? && sensor_data.signal_strength < 30
      score -= 10
    end

    [score, 0].max
  end

  def check_alerts(device, sensor_data)
    alerts = []

    # 温度アラート
    if sensor_data.temperature.present?
      if sensor_data.temperature > 35
        alerts << create_alert(device, 'high_temperature', "Temperature too high: #{sensor_data.temperature}°C")
      elsif sensor_data.temperature < 5
        alerts << create_alert(device, 'low_temperature', "Temperature too low: #{sensor_data.temperature}°C")
      end
    end

    # バッテリーアラート
    if sensor_data.battery_level.present? && sensor_data.battery_level < 15
      alerts << create_alert(device, 'low_battery', "Battery level low: #{sensor_data.battery_level}%")
    end

    # 信号強度アラート
    if sensor_data.signal_strength.present? && sensor_data.signal_strength < 20
      alerts << create_alert(device, 'weak_signal', "Signal strength weak: #{sensor_data.signal_strength}%")
    end

    # アラートがある場合は通知
    if alerts.any?
      SendAlertNotificationJob.perform_async(device.device_id, alerts)
    end
  end

  def create_alert(device, alert_type, message)
    {
      device_id: device.device_id,
      alert_type: alert_type,
      message: message,
      timestamp: Time.current.iso8601,
      severity: determine_severity(alert_type)
    }
  end

  def determine_severity(alert_type)
    case alert_type
    when 'high_temperature', 'low_temperature'
      'medium'
    when 'low_battery'
      'high'
    when 'weak_signal'
      'low'
    else
      'medium'
    end
  end

  def update_statistics(device_id, sensor_data)
    # 日次統計の更新
    date_key = sensor_data.timestamp.strftime('%Y-%m-%d')
    stats_key = "daily_stats:#{device_id}:#{date_key}"

    Rails.cache.fetch(stats_key, expires_in: 25.hours) do
      calculate_daily_stats(device_id, sensor_data.timestamp.to_date)
    end

    # キャッシュを更新
    Rails.cache.delete(stats_key)
  end

  def calculate_daily_stats(device_id, date)
    daily_data = SensorData.find_by_device_and_date_range(
      device_id,
      date.beginning_of_day,
      date.end_of_day
    )

    return {} if daily_data.empty?

    temperatures = daily_data.map(&:temperature).compact
    humidities = daily_data.map(&:humidity).compact

    {
      date: date.to_s,
      data_count: daily_data.size,
      temperature: {
        min: temperatures.min,
        max: temperatures.max,
        avg: temperatures.sum / temperatures.size.to_f
      },
      humidity: {
        min: humidities.min,
        max: humidities.max,
        avg: humidities.sum / humidities.size.to_f
      }
    }
  end

  def should_notify?(sensor_data)
    # 通知が必要かどうかの判定
    sensor_data.data_quality == 'poor' ||
    sensor_data.battery_level.to_i < 15 ||
    sensor_data.temperature.to_i > 35 ||
    sensor_data.temperature.to_i < 5
  end

  def notify_external_systems(device, sensor_data)
    # 外部システムへの通知（例：Slack、メール、Webhook等）
    logger.info "Notifying external systems for device #{device.device_id}"

    # 実際の実装では、外部APIへのHTTPリクエストなどを行う
    # NotifyExternalSystemJob.perform_async(device.device_id, sensor_data.id)
  end
end
