# IoTデバイス情報を管理するDynamoDBモデル
class Device
  include Dynamoid::Document

  # テーブル設定
  table name: :devices, key: :device_id

  # Primary Key
  field :device_id, :string

  # デバイス基本情報
  field :name, :string
  field :device_type, :string
  field :manufacturer, :string
  field :model, :string
  field :firmware_version, :string
  field :status, :string, default: 'active'

  # 位置情報
  field :location, :map
  field :installation_date, :datetime

  # メタデータ
  field :description, :string
  field :tags, :array, of: :string

  # タイムスタンプ（Dynamoidが自動設定）
  # field :created_at, :datetime
  # field :updated_at, :datetime

  # バリデーション
  validates :device_id, presence: true
  validates :name, presence: true
  validates :device_type, presence: true, inclusion: {
    in: %w[temperature_sensor humidity_sensor pressure_sensor multi_sensor gateway],
    message: "%{value} is not a valid device type"
  }
  validates :status, inclusion: {
    in: %w[active inactive maintenance error],
    message: "%{value} is not a valid status"
  }

  # インスタンスメソッド
  def active?
    status == 'active'
  end

  def inactive?
    status == 'inactive'
  end

  def in_maintenance?
    status == 'maintenance'
  end

  def error?
    status == 'error'
  end

  def location_coordinates
    return nil unless location.present?
    {
      latitude: location['latitude'],
      longitude: location['longitude']
    }
  end

  def set_location(latitude, longitude)
    self.location = {
      'latitude' => latitude.to_f,
      'longitude' => longitude.to_f
    }
  end

  # クラスメソッド
  def self.find_by_location(latitude, longitude, radius_km = 1.0)
    # 簡易的な位置検索（実際の実装では地理空間インデックスを使用）
    all.select do |device|
      next false unless device.location.present?

      device_lat = device.location['latitude'].to_f
      device_lng = device.location['longitude'].to_f

      distance = calculate_distance(latitude, longitude, device_lat, device_lng)
      distance <= radius_km
    end
  end

  def self.calculate_distance(lat1, lng1, lat2, lng2)
    # Haversine formula for calculating distance between two points
    rad_per_deg = Math::PI / 180
    rlat1 = lat1 * rad_per_deg
    rlat2 = lat2 * rad_per_deg
    dlat = rlat2 - rlat1
    dlng = (lng2 - lng1) * rad_per_deg

    a = Math.sin(dlat/2)**2 + Math.cos(rlat1) * Math.cos(rlat2) * Math.sin(dlng/2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))

    6371 * c # Earth's radius in kilometers
  end

  # JSON表現
  def as_json(options = {})
    super(options).merge(
      location_coordinates: location_coordinates,
      is_active: active?
    )
  end
end
