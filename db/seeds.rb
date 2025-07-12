# IoTデータ収集・分析プラットフォーム用サンプルデータ

puts "🌱 IoTプラットフォームのサンプルデータを生成中..."

# DynamoDBテーブルの作成（必要に応じて）
begin
  puts "📊 DynamoDBテーブルの確認中..."
  Dynamoid.adapter.list_tables
  puts "✅ DynamoDB接続確認完了"
rescue => e
  puts "❌ DynamoDB接続エラー: #{e.message}"
  puts "LocalStackが起動していることを確認してください"
  exit 1
end

# 既存データのクリア（開発環境のみ）
if Rails.env.development?
  puts "🧹 既存データをクリア中..."
  begin
    # Dynamoidではdestroy_allが使用できないため、個別削除
    Device.all.each(&:destroy) rescue nil
    puts "✅ 既存データクリア完了"
  rescue => e
    puts "⚠️  データクリア中にエラー: #{e.message}"
  end
end

# デバイスの作成
puts "🔧 IoTデバイスを作成中..."

devices_data = [
  {
    device_id: "temp_sensor_001",
    name: "温度センサー 1号機",
    device_type: "temperature_sensor",
    manufacturer: "SensorTech Co.",
    model: "ST-TEMP-100",
    firmware_version: "1.2.3",
    status: "active",
    description: "農場エリアA用温度センサー",
    location: { latitude: 35.6762, longitude: 139.6503 },
    installation_date: 1.month.ago,
    tags: ["agriculture", "temperature", "area_a"]
  },
  {
    device_id: "multi_sensor_001",
    name: "マルチセンサー 1号機",
    device_type: "multi_sensor",
    manufacturer: "IoT Solutions Inc.",
    model: "IOT-MULTI-200",
    firmware_version: "2.1.0",
    status: "active",
    description: "農場エリアB用多機能センサー",
    location: { latitude: 35.6764, longitude: 139.6505 },
    installation_date: 2.weeks.ago,
    tags: ["agriculture", "multi_sensor", "area_b"]
  },
  {
    device_id: "humidity_sensor_001",
    name: "湿度センサー 1号機",
    device_type: "humidity_sensor",
    manufacturer: "SensorTech Co.",
    model: "ST-HUM-150",
    firmware_version: "1.1.5",
    status: "active",
    description: "温室用湿度センサー",
    location: { latitude: 35.6760, longitude: 139.6500 },
    installation_date: 3.weeks.ago,
    tags: ["greenhouse", "humidity"]
  },
  {
    device_id: "pressure_sensor_001",
    name: "気圧センサー 1号機",
    device_type: "pressure_sensor",
    manufacturer: "WeatherTech Ltd.",
    model: "WT-PRESS-300",
    firmware_version: "1.0.8",
    status: "maintenance",
    description: "気象観測用気圧センサー",
    location: { latitude: 35.6758, longitude: 139.6498 },
    installation_date: 1.week.ago,
    tags: ["weather", "pressure"]
  },
  {
    device_id: "gateway_001",
    name: "IoTゲートウェイ 1号機",
    device_type: "gateway",
    manufacturer: "Gateway Systems Co.",
    model: "GS-IOT-500",
    firmware_version: "3.2.1",
    status: "active",
    description: "センサーデータ収集用ゲートウェイ",
    location: { latitude: 35.6761, longitude: 139.6502 },
    installation_date: 1.month.ago,
    tags: ["gateway", "data_collection"]
  }
]

devices = []
devices_data.each do |device_data|
  device = Device.find(device_data[:device_id]) rescue nil
  if device.nil?
    device = Device.create!(device_data)
    puts "  ✅ デバイス作成: #{device.name} (#{device.device_id})"
  else
    puts "  ⚠️  デバイス既存: #{device.name} (#{device.device_id})"
  end
  devices << device
end

puts "📊 #{devices.count}台のデバイスを作成しました"

# センサーデータの生成
puts "📈 センサーデータを生成中..."

# 過去7日間のデータを生成
start_date = 7.days.ago
end_date = Time.current

devices.each do |device|
  next if device.status != 'active'  # アクティブなデバイスのみ

  puts "  📊 #{device.name}のデータを生成中..."

  current_time = start_date
  data_count = 0

  while current_time <= end_date
    # 1時間ごとにデータを生成（ランダムに一部スキップ）
    if rand(100) < 85  # 85%の確率でデータを生成

      sensor_data_params = {
        device_id: device.device_id,
        timestamp: current_time
      }

      # デバイスタイプに応じてセンサーデータを生成
      case device.device_type
      when 'temperature_sensor'
        sensor_data_params.merge!(
          temperature: rand(15.0..35.0).round(1),
          battery_level: rand(70..100),
          signal_strength: rand(60..95)
        )

      when 'humidity_sensor'
        sensor_data_params.merge!(
          humidity: rand(40.0..80.0).round(1),
          temperature: rand(18.0..28.0).round(1),
          battery_level: rand(75..100),
          signal_strength: rand(65..90)
        )

      when 'pressure_sensor'
        sensor_data_params.merge!(
          pressure: rand(980.0..1030.0).round(1),
          temperature: rand(10.0..30.0).round(1),
          battery_level: rand(80..100),
          signal_strength: rand(70..95)
        )

      when 'multi_sensor'
        sensor_data_params.merge!(
          temperature: rand(15.0..35.0).round(1),
          humidity: rand(40.0..80.0).round(1),
          pressure: rand(980.0..1030.0).round(1),
          soil_moisture: rand(20.0..70.0).round(1),
          ph_level: rand(6.0..8.0).round(1),
          light_intensity: rand(100..2000),
          battery_level: rand(60..100),
          signal_strength: rand(50..90)
        )

      when 'gateway'
        # ゲートウェイは他のセンサーからのデータを中継
        sensor_data_params.merge!(
          temperature: rand(20.0..30.0).round(1),
          battery_level: 100,  # 外部電源
          signal_strength: rand(80..100)
        )
      end

      # 時間帯による変動を追加
      hour = current_time.hour
      if sensor_data_params[:temperature]
        # 昼間は温度が高く、夜間は低く
        temp_adjustment = Math.sin((hour - 6) * Math::PI / 12) * 5
        sensor_data_params[:temperature] += temp_adjustment
        sensor_data_params[:temperature] = sensor_data_params[:temperature].round(1)
      end

      # データ品質をランダムに設定
      quality_rand = rand(100)
      if quality_rand < 5
        sensor_data_params[:data_quality] = 'poor'
      elsif quality_rand < 15
        sensor_data_params[:data_quality] = 'fair'
      else
        sensor_data_params[:data_quality] = 'good'
      end

      # 位置情報を追加（デバイスが移動する場合のシミュレーション）
      if device.location.present?
        lat_offset = rand(-0.001..0.001)
        lng_offset = rand(-0.001..0.001)
        sensor_data_params[:location] = {
          latitude: device.location['latitude'].to_f + lat_offset,
          longitude: device.location['longitude'].to_f + lng_offset
        }
      end

      # センサーデータを作成
      sensor_data = SensorData.create_from_device_reading(
        device.device_id,
        sensor_data_params
      )

      begin
        if sensor_data.save
          data_count += 1
        else
          # 重複エラーの場合はスキップ
          puts "    ⚠️  データスキップ: #{sensor_data.errors.full_messages.join(', ')}" if sensor_data.errors.any?
        end
      rescue Dynamoid::Errors::RecordNotUnique
        # 重複レコードの場合はスキップ
        puts "    ⚠️  重複データスキップ"
      end
    end

    current_time += 1.hour
  end

  puts "    ✅ #{data_count}件のデータを生成"
end

# 統計情報の表示
puts "\n📊 データ生成完了！"
puts "=" * 50

total_devices = Device.count
active_devices = Device.where(status: 'active').count
total_sensor_data = SensorData.count

puts "🔧 総デバイス数: #{total_devices}"
puts "✅ アクティブデバイス数: #{active_devices}"
puts "📈 総センサーデータ数: #{total_sensor_data}"

# デバイスタイプ別の統計
device_types = Device.all.group_by(&:device_type)
puts "\n📋 デバイスタイプ別統計:"
device_types.each do |type, devices|
  puts "  #{type}: #{devices.count}台"
end

# 最新のセンサーデータをいくつか表示
puts "\n📊 最新のセンサーデータ例:"
SensorData.all.sort_by(&:timestamp).last(3).each do |data|
  device = Device.find(data.device_id)
  puts "  #{device.name}: #{data.sensor_values} (#{data.timestamp.strftime('%Y-%m-%d %H:%M')})"
end

puts "\n🎉 サンプルデータ生成が完了しました！"
puts "🚀 アプリケーションを起動して http://localhost:3000/health でヘルスチェックを確認できます"
