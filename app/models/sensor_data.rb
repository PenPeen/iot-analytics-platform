# IoTセンサーデータを管理する時系列DynamoDBモデル
class SensorData
  include Dynamoid::Document

  # テーブル設定（時系列データ用の複合キー）
  table name: :sensor_data, key: :partition_key, range_key: :sort_key

  # Primary Keys (時系列データ用設計)
  field :partition_key, :string    # device#{device_id}#{date}
  field :sort_key, :string         # sensor#{timestamp}

  # デバイス情報
  field :device_id, :string
  field :timestamp, :datetime

  # センサーデータ
  field :temperature, :number
  field :humidity, :number
  field :pressure, :number
  field :co2_level, :number
  field :light_intensity, :number
  field :soil_moisture, :number
  field :ph_level, :number

  # 位置情報（デバイスが移動する場合）
  field :location, :map

  # メタデータ
  field :data_quality, :string, default: 'good'
  field :battery_level, :number
  field :signal_strength, :number
  field :raw_data, :map

  # バリデーション
  validates :device_id, presence: true
  validates :timestamp, presence: true
  validates :data_quality, inclusion: {
    in: %w[excellent good fair poor],
    message: "%{value} is not a valid data quality"
  }

  # コールバック
  before_save :set_partition_and_sort_keys
  before_save :validate_sensor_data

  # Global Secondary Index for device queries
  global_secondary_index hash_key: :device_id, range_key: :timestamp, name: 'device_timestamp_index'

  # インスタンスメソッド
  def sensor_values
    {
      temperature: temperature,
      humidity: humidity,
      pressure: pressure,
      co2_level: co2_level,
      light_intensity: light_intensity,
      soil_moisture: soil_moisture,
      ph_level: ph_level
    }.compact
  end

  def has_temperature?
    temperature.present?
  end

  def has_humidity?
    humidity.present?
  end

  def has_environmental_data?
    temperature.present? || humidity.present? || pressure.present?
  end

  def has_agriculture_data?
    soil_moisture.present? || ph_level.present?
  end

  def data_quality_score
    case data_quality
    when 'excellent' then 100
    when 'good' then 80
    when 'fair' then 60
    when 'poor' then 40
    else 0
    end
  end

  def location_coordinates
    return nil unless location.present?
    {
      latitude: location['latitude'],
      longitude: location['longitude']
    }
  end

  # クラスメソッド
  def self.create_from_device_reading(device_id, reading_data)
    timestamp = reading_data[:timestamp] || Time.current

    new(
      device_id: device_id,
      timestamp: timestamp,
      temperature: reading_data[:temperature],
      humidity: reading_data[:humidity],
      pressure: reading_data[:pressure],
      co2_level: reading_data[:co2_level],
      light_intensity: reading_data[:light_intensity],
      soil_moisture: reading_data[:soil_moisture],
      ph_level: reading_data[:ph_level],
      location: reading_data[:location],
      battery_level: reading_data[:battery_level],
      signal_strength: reading_data[:signal_strength],
      raw_data: reading_data[:raw_data]
    )
  end

  def self.find_by_device_and_date_range(device_id, start_date, end_date)
    # 日付範囲でパーティションキーを生成
    date_range = start_date.to_date..end_date.to_date
    results = []

    date_range.each do |date|
      partition_key = generate_partition_key(device_id, date)

      # その日のデータを取得
      daily_data = where(
        partition_key: partition_key,
        'sort_key.begins_with': 'sensor#'
      ).where('timestamp.between': [start_date, end_date])

      results.concat(daily_data.to_a)
    end

    results.sort_by(&:timestamp)
  end

  def self.latest_by_device(device_id, limit = 10)
    # デバイスIDでフィルタして、タイムスタンプでソート
    all_data = where(device_id: device_id).to_a
    sorted_data = all_data.sort_by(&:timestamp).reverse
    sorted_data.first(limit)
  end

  def self.aggregate_hourly(device_id, date)
    data = find_by_device_and_date_range(device_id, date.beginning_of_day, date.end_of_day)

    hourly_data = data.group_by { |d| d.timestamp.hour }

    hourly_data.map do |hour, readings|
      {
        hour: hour,
        count: readings.size,
        avg_temperature: readings.map(&:temperature).compact.sum / readings.size.to_f,
        avg_humidity: readings.map(&:humidity).compact.sum / readings.size.to_f,
        avg_pressure: readings.map(&:pressure).compact.sum / readings.size.to_f
      }
    end
  end

  # JSON表現
  def as_json(options = {})
    super(options).merge(
      sensor_values: sensor_values,
      location_coordinates: location_coordinates,
      data_quality_score: data_quality_score
    )
  end

  private

  def set_partition_and_sort_keys
    date_str = timestamp.strftime('%Y-%m-%d')
    timestamp_str = timestamp.utc.iso8601

    self.partition_key = self.class.generate_partition_key(device_id, date_str)
    self.sort_key = "sensor##{timestamp_str}"
  end

  def self.generate_partition_key(device_id, date)
    date_str = date.is_a?(String) ? date : date.strftime('%Y-%m-%d')
    "device##{device_id}##{date_str}"
  end

  def validate_sensor_data
    # 少なくとも1つのセンサー値が必要
    unless sensor_values.values.any?(&:present?)
      errors.add(:base, 'At least one sensor value must be present')
    end

    # 温度の範囲チェック
    if temperature.present? && (temperature < -50 || temperature > 100)
      errors.add(:temperature, 'must be between -50 and 100 degrees Celsius')
    end

    # 湿度の範囲チェック
    if humidity.present? && (humidity < 0 || humidity > 100)
      errors.add(:humidity, 'must be between 0 and 100 percent')
    end

    # バッテリーレベルの範囲チェック
    if battery_level.present? && (battery_level < 0 || battery_level > 100)
      errors.add(:battery_level, 'must be between 0 and 100 percent')
    end
  end
end
