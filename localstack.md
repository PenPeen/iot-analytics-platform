# LocalStack について

## 📋 目次

1. [LocalStack とは？](#localstack-とは)
2. [なぜ LocalStack を使うのか？](#なぜ-localstack-を使うのか)
3. [このプロジェクトでの LocalStack 活用](#このプロジェクトでの-localstack-活用)
4. [LocalStack の設定](#localstack-の設定)
5. [使用しているAWSサービス](#使用しているawsサービス)
6. [LocalStack の操作方法](#localstack-の操作方法)
7. [トラブルシューティング](#トラブルシューティング)
8. [参考リンク](#参考リンク)

---

## LocalStack とは？

LocalStack は、**AWS のクラウドサービスをローカル環境で模擬（エミュレート）するツール**です。

### 🎯 LocalStack の特徴

- **完全ローカル実行**: インターネット接続なしで AWS サービスを使用可能
- **コスト削減**: 実際の AWS を使わないため、開発・テスト費用が0円
- **高速開発**: ローカル環境なのでレスポンスが速い
- **安全性**: 本番環境に影響を与えずに開発・テスト可能
- **Docker 対応**: 1つのコンテナで複数の AWS サービスを提供

### 🔧 動作原理

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ あなたのアプリ  │───▶│ LocalStack       │───▶│ ローカルストレージ │
│ (Rails など)    │    │ (AWS エミュレータ)│    │ (ファイル/メモリ)│
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

実際の AWS への接続を LocalStack が代替し、ローカル環境で同等の機能を提供します。

### 📡 通信の流れ

1. **Rails API** → `http://localhost:4566` (LocalStackのエンドポイント)
2. **LocalStack** が受信したリクエストを解析
3. **LocalStack** 内部で該当するAWSサービスエミュレータに転送
4. **エミュレータ** が処理を実行してレスポンスを返す
5. **LocalStack** がレスポンスを Rails API に返す

---

## なぜ LocalStack を使うのか？

### 💰 コスト面のメリット

| 従来の開発方法 | LocalStack を使用 |
|---------------|------------------|
| AWS 利用料金が発生 | **完全無料** |
| 本番環境でのテスト | ローカル環境で安全にテスト |
| 複数環境の管理コスト | 1つのローカル環境で完結 |

### ⚡ 開発効率のメリット

- **即座にリセット**: 環境を瞬時に初期化可能
- **オフライン開発**: インターネット接続不要
- **高速レスポンス**: ネットワーク遅延なし
- **並行開発**: 複数の開発者が独立した環境で作業

### 🛡️ セキュリティのメリット

- **本番データの保護**: 実際のデータに影響しない
- **権限管理不要**: ローカル環境なので AWS IAM 設定が不要
- **実験的な変更**: 安全に新機能をテスト可能

---

## このプロジェクトでの LocalStack 活用

### 🏗️ アーキテクチャ図

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Rails API       │───▶│ LocalStack       │───▶│ 内部エミュレータ   │
│                 │    │ (ポート: 4566)    │    │ - DynamoDB      │
│ AWS SDK         │    │                  │    │ - S3            │
│ ↓               │    │ 🔄 リクエスト      │    │ - SNS/SQS       │
│ endpoint設定     │    │    ルーティング    │    │ - その他...      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │                       ▼                       │
         │              ┌──────────────────┐              │
         │              │ S3 Bucket        │              │
         │              │ (ファイル保存)    │              │
         │              └──────────────────┘              │
         │                       │                       │
         │                       ▼                       │
         │              ┌──────────────────┐              │
         │              │ SNS/SQS          │              │
         │              │ (メッセージング)  │              │
         └──────────────▶└──────────────────┘◀─────────────┘
```

### 📊 データフロー

1. **IoT センサーデータ** → Rails API
2. **Rails API** → LocalStack の DynamoDB (データ保存)
3. **Rails API** → LocalStack の S3 (ファイル保存)
4. **Rails API** → LocalStack の SNS/SQS (通知・メッセージング)

### 🎯 具体的な活用例

#### 1. DynamoDB でのセンサーデータ管理
```ruby
# app/models/sensor_data.rb
class SensorData
  include Dynamoid::Document

  # LocalStack の DynamoDB に保存
  table name: :sensor_data, key: :partition_key, range_key: :sort_key

  field :device_id, :string
  field :timestamp, :datetime
  field :temperature, :number
  field :humidity, :number
  # ...
end
```

#### 2. 時系列データの効率的な保存
```ruby
# パーティションキー設計例
partition_key = "device##{device_id}##{date}"
sort_key = "sensor##{timestamp}"

# 例: "device#sensor_001#2024-01-15" | "sensor#2024-01-15T10:30:00Z"
```

---

## LocalStack の設定

### 🐳 Docker Compose 設定

```yaml
# docker-compose.yml
services:
  localstack:
    container_name: localstack_main
    image: localstack/localstack:3.0
    ports:
      - "4566:4566"          # メインエンドポイント
      - "4510-4559:4510-4559"  # 追加サービス用ポート
    environment:
      - DEBUG=1                           # デバッグモード有効
      - SERVICES=dynamodb,s3,sns,sqs      # 使用するサービス
      - AWS_ACCESS_KEY_ID=test            # テスト用認証情報
      - AWS_SECRET_ACCESS_KEY=test
      - AWS_DEFAULT_REGION=ap-northeast-1 # 東京リージョン
      - DYNAMODB_SHARE_DB=1               # DynamoDB データ共有
      - PERSISTENCE=1                     # データ永続化
    volumes:
      - "./localstack/data:/var/lib/localstack"  # データ保存先
      - "/var/run/docker.sock:/var/run/docker.sock"  # Docker 連携
```

### ⚙️ Rails アプリケーション設定

```ruby
# config/initializers/dynamoid.rb
Dynamoid.configure do |config|
  if Rails.env.development? || Rails.env.test?
    # LocalStack エンドポイントを指定
    config.endpoint = ENV.fetch('AWS_ENDPOINT', 'http://localhost:4566')
    config.region = ENV.fetch('AWS_REGION', 'ap-northeast-1')
    config.access_key = ENV.fetch('AWS_ACCESS_KEY_ID', 'test')
    config.secret_key = ENV.fetch('AWS_SECRET_ACCESS_KEY', 'test')
  end

  # テーブル名の名前空間
  config.namespace = "iot_platform_#{Rails.env}"
end
```

### 📝 環境変数設定

```bash
# .env ファイル
AWS_ENDPOINT=http://localstack:4566
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_REGION=ap-northeast-1
DYNAMODB_ENDPOINT=http://localstack:4566
DYNAMODB_REGION=ap-northeast-1
```

---

## 使用しているAWSサービス

### 1. 🗄️ DynamoDB

**用途**: IoT センサーデータの時系列保存

**特徴**:
- 高速な読み書き性能
- 自動スケーリング
- 時系列データに最適

**テーブル構造**:
```
📊 sensor_data テーブル
├── partition_key: "device#デバイスID#日付"
├── sort_key: "sensor#タイムスタンプ"
├── device_id: デバイス識別子
├── timestamp: データ取得時刻
├── temperature: 温度
├── humidity: 湿度
└── その他センサー値...
```

### 2. 🪣 S3

**用途**: ファイル保存（予定）

**活用例**:
- センサーデータのバックアップ
- 設定ファイルの保存
- ログファイルのアーカイブ

### 3. 📢 SNS (Simple Notification Service)

**用途**: 通知サービス（予定）

**活用例**:
- アラート通知
- システム状態の変更通知
- 他システムへの連携通知

### 4. 📨 SQS (Simple Queue Service)

**用途**: メッセージキューイング（予定）

**活用例**:
- 非同期データ処理
- バックグラウンドジョブ
- システム間連携

---

## LocalStack の操作方法

### 🚀 起動・停止

```bash
# LocalStack を含む全サービス起動
docker-compose up -d

# LocalStack のみ起動
docker-compose up -d localstack

# 停止
docker-compose down

# データも削除して停止
docker-compose down -v
```

### 🔍 動作確認

```bash
# LocalStack の健全性チェック
curl http://localhost:4566/health

# サービス一覧確認
curl http://localhost:4566/_localstack/health | jq

# DynamoDB テーブル一覧
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
```

### 📊 DynamoDB 操作例

```bash
# テーブル作成
aws --endpoint-url=http://localhost:4566 dynamodb create-table \
  --table-name test-table \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# データ挿入
aws --endpoint-url=http://localhost:4566 dynamodb put-item \
  --table-name test-table \
  --item '{"id": {"S": "test-001"}, "name": {"S": "テストデータ"}}'

# データ取得
aws --endpoint-url=http://localhost:4566 dynamodb get-item \
  --table-name test-table \
  --key '{"id": {"S": "test-001"}}'
```

### 🔧 Rails からの操作

```ruby
# Rails コンソールでの操作例
rails console

# DynamoDB テーブル一覧
Dynamoid.adapter.list_tables

# デバイス作成
device = Device.create!(
  device_id: "test_sensor_001",
  name: "テストセンサー",
  device_type: "temperature_sensor",
  status: "active"
)

# センサーデータ作成
sensor_data = SensorData.create!(
  device_id: "test_sensor_001",
  timestamp: Time.current,
  temperature: 25.5,
  humidity: 60.0
)
```

---

## トラブルシューティング

### ❌ よくある問題と解決方法

#### 1. LocalStack が起動しない

**症状**: `docker-compose up -d` でエラーが発生

**解決方法**:
```bash
# Docker Desktop が起動しているか確認
docker --version

# ポート 4566 が使用されていないか確認
lsof -i :4566

# 既存のコンテナを削除
docker-compose down -v
docker-compose up -d
```

#### 2. DynamoDB 接続エラー

**症状**: `Aws::DynamoDB::Errors::NetworkingError`

**解決方法**:
```bash
# LocalStack の状態確認
docker-compose logs localstack

# LocalStack 再起動
docker-compose restart localstack

# 接続確認
curl http://localhost:4566/health
```

#### 3. データが保存されない

**症状**: Rails からデータを保存してもテーブルが空

**解決方法**:
```ruby
# Rails コンソールで確認
rails console

# Dynamoid の設定確認
Dynamoid.config.endpoint
# => "http://localhost:4566"

# テーブル同期
Dynamoid.adapter.sync_all_tables
```

#### 4. 環境変数が読み込まれない

**症状**: AWS_ENDPOINT が設定されていない

**解決方法**:
```bash
# .env ファイルの存在確認
ls -la .env

# 環境変数の確認
docker-compose exec rails env | grep AWS
```

### 🔍 デバッグ方法

```bash
# LocalStack のログ確認
docker-compose logs -f localstack

# Rails のログ確認
docker-compose logs -f rails

# DynamoDB の詳細情報
aws --endpoint-url=http://localhost:4566 dynamodb describe-table \
  --table-name iot_platform_development_devices
```

---

## 参考リンク

### 📚 公式ドキュメント

- [LocalStack 公式サイト](https://localstack.cloud/)
- [LocalStack ドキュメント](https://docs.localstack.cloud/)
- [LocalStack GitHub](https://github.com/localstack/localstack)

### 🛠️ 関連技術

- [AWS DynamoDB](https://aws.amazon.com/jp/dynamodb/)
- [Dynamoid Gem](https://github.com/Dynamoid/dynamoid)
- [Docker Compose](https://docs.docker.com/compose/)

### 💡 学習リソース

- [LocalStack チュートリアル](https://docs.localstack.cloud/tutorials/)
- [DynamoDB 設計パターン](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [Rails API 開発](https://guides.rubyonrails.org/api_app.html)

---

## 📝 まとめ

LocalStack は、このIoTプラットフォームプロジェクトにおいて：

1. **コスト削減**: AWS 利用料金を0円に
2. **開発効率向上**: ローカル環境での高速開発
3. **安全性確保**: 本番環境に影響しない実験環境
4. **学習促進**: AWS サービスの理解を深める

これらのメリットを提供し、効率的なクラウドアプリケーション開発を可能にしています。

LocalStack を活用することで、実際の AWS 環境と同等の機能をローカル環境で体験でき、クラウド開発のスキルを安全に習得できます。
