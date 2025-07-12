# Dynamoid とは

## 概要

Dynamoidは、Amazon DynamoDB用のRuby ORM（Object-Relational Mapping）ライブラリです。ActiveRecordに似た機能を提供し、DynamoDBをRubyアプリケーションで使いやすくします。

### 主な特徴

- **ActiveRecordライクな操作**: ActiveRecordに慣れている開発者にとって親しみやすいAPI
- **DynamoDB特有の機能サポート**: NoSQLデータベースの特性を活かした設計
- **バリデーション**: ActiveModelのバリデーション機能を内蔵
- **アソシエーション**: モデル間の関連付けをサポート
- **ローカル開発**: LocalStackやDynamoDB Localでのオフライン開発が可能

### DynamoDBの特徴

DynamoDBは従来のリレーショナルデータベースとは大きく異なります：

- **NoSQLデータベース**: スキーマレスで柔軟なデータ構造
- **高速・高可用性**: 大規模なトラフィックに対応
- **シンプルなクエリ**: 複雑なJOINやトランザクションは制限される
- **キーバリューストア**: パーティションキーとソートキーによるデータアクセス

## このプロジェクトでの使用方法

### 設定ファイル

```ruby
# config/initializers/dynamoid.rb
Dynamoid.configure do |config|
  # LocalStack endpoint (開発・テスト環境)
  if Rails.env.development? || Rails.env.test?
    config.endpoint = ENV.fetch('AWS_ENDPOINT', 'http://localhost:4566')
    config.region = ENV.fetch('AWS_REGION', 'ap-northeast-1')
    config.access_key = ENV.fetch('AWS_ACCESS_KEY_ID', 'test')
    config.secret_key = ENV.fetch('AWS_SECRET_ACCESS_KEY', 'test')
  else
    # 本番環境設定
    config.region = ENV.fetch('AWS_REGION', 'ap-northeast-1')
  end

  # テーブル設定
  config.namespace = "iot_platform_#{Rails.env}"
  config.warn_on_scan = true
  config.timestamps = true
  config.read_capacity = 5
  config.write_capacity = 5
end
```

### モデル定義

#### 1. Deviceモデル（IoTデバイス情報）

```ruby
class Device
  include Dynamoid::Document

  # テーブル設定
  table name: :devices, key: :device_id

  # フィールド定義
  field :device_id, :string      # Primary Key
  field :name, :string           # デバイス名
  field :device_type, :string    # デバイスタイプ
  field :manufacturer, :string   # メーカー
  field :model, :string          # モデル
  field :firmware_version, :string
  field :status, :string, default: 'active'
  field :location, :map          # 位置情報（緯度・経度）
  field :installation_date, :datetime
  field :description, :string
  field :tags, :array, of: :string

  # バリデーション
  validates :device_id, presence: true
  validates :name, presence: true
  validates :device_type, inclusion: {
    in: %w[temperature_sensor humidity_sensor pressure_sensor multi_sensor gateway]
  }
  validates :status, inclusion: {
    in: %w[active inactive maintenance error]
  }
end
```

#### 2. SensorDataモデル（時系列データ）

```ruby
class SensorData
  include Dynamoid::Document

  # 複合キー設定（時系列データ用）
  table name: :sensor_data, key: :partition_key, range_key: :sort_key

  # Primary Keys
  field :partition_key, :string    # device#{device_id}#{date}
  field :sort_key, :string         # sensor#{timestamp}

  # データフィールド
  field :device_id, :string
  field :timestamp, :datetime
  field :temperature, :number
  field :humidity, :number
  field :pressure, :number
  field :co2_level, :number
  field :light_intensity, :number
  field :soil_moisture, :number
  field :ph_level, :number
  field :location, :map
  field :data_quality, :string, default: 'good'
  field :battery_level, :number
  field :signal_strength, :number
  field :raw_data, :map

  # Global Secondary Index
  global_secondary_index hash_key: :device_id, range_key: :timestamp, name: 'device_timestamp_index'

  # コールバック
  before_save :set_partition_and_sort_keys
  before_save :validate_sensor_data

  private

  def set_partition_and_sort_keys
    date_str = timestamp.strftime('%Y-%m-%d')
    timestamp_str = timestamp.utc.iso8601

    self.partition_key = "device##{device_id}##{date_str}"
    self.sort_key = "sensor##{timestamp_str}"
  end
end
```

### 基本的な操作

#### 1. データ作成

```ruby
# デバイス作成
device = Device.create(
  device_id: 'sensor001',
  name: 'Temperature Sensor 1',
  device_type: 'temperature_sensor',
  manufacturer: 'SensorTech',
  location: { 'latitude' => 35.6762, 'longitude' => 139.6503 }
)

# センサーデータ作成
sensor_data = SensorData.create(
  device_id: 'sensor001',
  timestamp: Time.current,
  temperature: 25.5,
  humidity: 60.0,
  pressure: 1013.25
)
```

#### 2. データ検索

```ruby
# IDで検索
device = Device.find('sensor001')

# 条件で検索
active_devices = Device.where(status: 'active').to_a

# 時系列データの検索
recent_data = SensorData.where(device_id: 'sensor001')
                       .where('timestamp.gt': 1.hour.ago)
                       .to_a
```

#### 3. データ更新

```ruby
# 単一フィールド更新
device.update_attribute(:status, 'maintenance')

# 複数フィールド更新
device.update_attributes(
  status: 'active',
  firmware_version: '2.1.0'
)
```

#### 4. データ削除

```ruby
# 単一レコード削除
device.destroy

# 条件による一括削除
Device.where(status: 'inactive').delete_all
```

### 時系列データの効率的な設計

このプロジェクトでは、センサーデータを効率的に扱うために以下の設計を採用しています：

#### パーティションキーの設計

```ruby
# パーティションキー: device#{device_id}#{date}
# 例: "device#sensor001#2024-01-15"
```

- **利点**: 同じデバイスの同じ日のデータが同じパーティションに格納される
- **効果**: 日付範囲でのクエリが高速化される

#### ソートキーの設計

```ruby
# ソートキー: sensor#{timestamp}
# 例: "sensor#2024-01-15T10:30:00Z"
```

- **利点**: 時系列順にデータが並ぶ
- **効果**: 時間範囲でのクエリが効率的

### エラーハンドリング

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  rescue_from Dynamoid::Errors::RecordNotFound, with: :handle_not_found
  rescue_from Dynamoid::Errors::DocumentNotValid, with: :handle_validation_error

  private

  def handle_not_found(exception)
    render json: { error: 'Record not found' }, status: :not_found
  end

  def handle_validation_error(exception)
    render json: { error: exception.message }, status: :unprocessable_entity
  end
end
```

### テーブル管理

```ruby
# テーブル一覧確認
Dynamoid.adapter.list_tables

# テーブル同期（開発環境）
Dynamoid.adapter.sync_all_tables

# 設定確認
Dynamoid.config.endpoint
```

## 利点と注意点

### 利点

1. **ActiveRecordライクなAPI**: 学習コストが低い
2. **DynamoDB最適化**: NoSQLの特性を活かした設計
3. **スケーラビリティ**: 大量データの高速処理
4. **ローカル開発**: LocalStackでのオフライン開発
5. **バリデーション**: データ整合性の確保

### 注意点

1. **制限されたクエリ**: 複雑なJOINや集計は不可
2. **スキーマ設計**: パーティションキーとソートキーの適切な設計が重要
3. **コスト**: 読み書き容量の設定に注意
4. **学習コスト**: DynamoDBの特性を理解する必要

## まとめ

Dynamoidは、DynamoDBをRubyアプリケーションで使いやすくする優れたORMです。このプロジェクトでは、IoTデバイス情報と時系列センサーデータを効率的に管理するために活用されています。

ActiveRecordに慣れた開発者にとって親しみやすいAPIを提供しながら、DynamoDBの高性能・高可用性の恩恵を受けることができます。ただし、NoSQLデータベースの特性を理解し、適切なデータ設計を行うことが成功の鍵となります。

## 参考リンク

- [Dynamoid GitHub](https://github.com/Dynamoid/dynamoid)
- [DynamoDB Developer Guide](https://docs.aws.amazon.com/dynamodb/)
- [LocalStack Documentation](https://docs.localstack.cloud/)
