# IoTデータ収集・分析プラットフォーム

Rails + DynamoDB（Dynamoid） + Kubernetes + Redis + LocalStack + Terraform を使用した本格的なIoTデータ収集・分析プラットフォームです。

## 🌟 概要

センサーデータの大量書き込みにDynamoDBを活用し、デバイス管理とデータ可視化をRailsで構築した学習目的のプラットフォームです。LocalStackによる完全ローカル開発環境、Kubernetesでのコンテナオーケストレーション、Redisキャッシング、Sidekiqによる非同期処理を統合しています。

## 🏗️ アーキテクチャ

```
┌─────────────┐    ┌──────────────┐    ┌─────────────────┐
│ IoTセンサー │───▶│ Rails API    │───▶│ DynamoDB        │
│ (5台構成)   │    │ (REST API)   │    │ (LocalStack)    │
└─────────────┘    └──────────────┘    └─────────────────┘
                           │                      │
                           ▼                      │
                   ┌──────────────┐               │
                   │ Redis Cache  │               │
                   │ (キャッシング)│               │
                   └──────────────┘               │
                           │                      │
                           ▼                      │
                   ┌──────────────┐               │
                   │ Sidekiq      │               │
                   │ (非同期処理)  │               │
                   └──────────────┘               │
                           │                      │
                           ▼                      │
                   ┌──────────────┐               │
                   │ PostgreSQL   │               │
                   │ (メタデータ)  │               │
                   └──────────────┘               │
                           │                      │
                           ▼                      │
                   ┌──────────────┐               │
                   │ Kubernetes   │◀──────────────┘
                   │ (オーケストレ │
                   │  ーション)   │
                   └──────────────┘
                           │
                           ▼
                   ┌──────────────┐
                   │ Terraform    │
                   │ (IaC)        │
                   └──────────────┘
```

## 🛠️ 技術スタック

### バックエンド
- **Framework**: Ruby on Rails 7.1 (API専用モード)
- **Database**: DynamoDB (時系列データ) + PostgreSQL (メタデータ)
- **ORM**: Dynamoid (DynamoDB) + ActiveRecord (PostgreSQL)
- **Cache**: Redis
- **Background Jobs**: Sidekiq
- **API**: RESTful API + JSON

### インフラ・DevOps
- **Container**: Docker + Docker Compose
- **Orchestration**: Kubernetes
- **Local AWS**: LocalStack (DynamoDB, S3, SNS, SQS)
- **IaC**: Terraform
- **Monitoring**: ヘルスチェック + システム監視

### フロントエンド
- **Dashboard**: モダンWebダッシュボード (HTML5 + Chart.js)
- **UI Framework**: CSS3 (グラデーション + ガラスモーフィズム)
- **Icons**: Lucide Icons
- **Charts**: Chart.js (リアルタイム更新)

## 🚀 主要機能

### 📊 リアルタイムダッシュボード
- **URL**: http://localhost:3000/dashboard.html
- 5台のIoTデバイス監視
- 時系列センサーデータ可視化
- システムヘルス監視
- 自動更新 (30秒間隔)

### 🔌 RESTful API
- **デバイス管理**: `/api/v1/devices`
- **センサーデータ**: `/api/v1/devices/:id/sensor_data`
- **分析機能**: `/api/v1/devices/:id/analytics`
- **ヘルスチェック**: `/health`

### 📈 データ処理
- **リアルタイム処理**: Sidekiqによる非同期データ処理
- **データ品質評価**: 自動品質チェック
- **アラート機能**: 異常値検知
- **統計集約**: 時間別・デバイス別集計

### 🏭 IoTデバイス構成
1. **温度センサー** (temperature_sensor_001)
2. **湿度センサー** (humidity_sensor_001)
3. **気圧センサー** (pressure_sensor_001) - メンテナンス中
4. **マルチセンサー** (multi_sensor_001)
5. **ゲートウェイ** (gateway_001)

## 📋 セットアップ手順

### 1. 前提条件

```bash
# 必要なツール
- Docker Desktop (4.0+)
- Docker Compose (2.0+)
- kubectl (1.20+)
- minikube (1.25+) [Kubernetes学習用]
- Terraform (1.0+) [オプション]
```

### 2. ワンクリック起動

```bash
# プロジェクトクローン
git clone <repository-url>
cd localstack_dynamoid

# 全サービス起動 (推奨)
chmod +x scripts/start.sh
./scripts/start.sh
```

### 3. 手動セットアップ

```bash
# 環境変数設定
cp env.example .env

# Docker環境起動
docker-compose up -d

# データベースセットアップ
docker-compose exec rails bin/rails db:create db:migrate

# サンプルデータ投入
docker-compose exec rails bin/rails db:seed

# サービス確認
docker-compose ps
```

### 4. Kubernetes展開

```bash
# minikube起動
minikube start

# 名前空間作成
kubectl apply -f k8s/namespace.yaml

# 設定ファイル適用
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

# サービス展開
kubectl apply -f k8s/deployments.yaml
kubectl apply -f k8s/services.yaml

# 状態確認
kubectl get pods -n iot-platform
kubectl get services -n iot-platform
```

### 5. Terraform (LocalStack)

```bash
cd terraform/

# Terraform初期化
terraform init

# 実行計画確認
terraform plan

# リソース作成
terraform apply -auto-approve

# 作成リソース確認
terraform output
```

## 🌐 サービスアクセス

| サービス | URL | 説明 |
|---------|-----|------|
| **Webダッシュボード** | http://localhost:3000/dashboard.html | メインダッシュボード |
| **Rails API** | http://localhost:3000/api/v1 | RESTful API |
| **ヘルスチェック** | http://localhost:3000/health | システム状態確認 |
| **LocalStack** | http://localhost:4566 | AWS サービスエミュレーション |
| **Redis** | localhost:6379 | キャッシュサーバー |
| **PostgreSQL** | localhost:5432 | データベース |

## 📊 API エンドポイント

### デバイス管理
```bash
# デバイス一覧取得
GET /api/v1/devices

# デバイス詳細取得
GET /api/v1/devices/:id

# デバイス作成
POST /api/v1/devices

# デバイス更新
PUT /api/v1/devices/:id

# デバイス削除
DELETE /api/v1/devices/:id
```

### センサーデータ
```bash
# センサーデータ取得
GET /api/v1/devices/:id/sensor_data

# センサーデータ投入
POST /api/v1/devices/:id/sensor_data

# 分析データ取得
GET /api/v1/devices/:id/analytics
```

### システム監視
```bash
# ヘルスチェック
GET /health

# ダッシュボードAPI
GET /api/dashboard

# リアルタイムデータ
GET /api/dashboard/realtime

# 統計情報
GET /api/dashboard/statistics
```

## 💾 データモデル

### DynamoDB設計 (時系列データ)

```ruby
# パーティションキー: device#{device_id}#{date}
# ソートキー: sensor#{timestamp}

# 例: device#sensor_001#2024-01-15 | sensor#2024-01-15T10:30:00Z
```

### センサーデータ構造

```json
{
  "device_id": "temperature_sensor_001",
  "timestamp": "2024-01-15T10:30:00Z",
  "temperature": 23.5,
  "humidity": 65.2,
  "pressure": 1013.25,
  "co2_level": 400,
  "light_intensity": 1200,
  "soil_moisture": 45.0,
  "ph_level": 6.8,
  "location": {
    "latitude": 35.6762,
    "longitude": 139.6503
  },
  "data_quality": "good",
  "battery_level": 85,
  "signal_strength": 92
}
```

## 🔧 開発ガイド

### ローカル開発

```bash
# ログ確認
docker-compose logs -f rails
docker-compose logs -f sidekiq

# Railsコンソール
docker-compose exec rails bin/rails console

# データベース確認
docker-compose exec rails bin/rails db

# テスト実行
docker-compose exec rails bin/rails test
```

### デバッグ

```bash
# サービス状態確認
curl http://localhost:3000/health

# API テスト
curl http://localhost:3000/api/v1/devices

# DynamoDB テーブル確認
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
```

## 📈 監視・運用

### システムヘルス
- DynamoDB接続状態
- Redis接続状態
- PostgreSQL接続状態
- レスポンス時間監視

### パフォーマンス指標
- API応答時間
- データ処理量
- キャッシュヒット率
- エラー率

## 🐛 トラブルシューティング

### よくある問題

1. **コンテナ起動失敗**
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

2. **DynamoDB接続エラー**
   ```bash
   # LocalStack再起動
   docker-compose restart localstack
   ```

3. **ポート競合**
   ```bash
   # 使用中ポート確認
   lsof -i :3000
   lsof -i :4566
   ```

## 📚 学習リソース

- [DynamoDB設計パターン](https://docs.aws.amazon.com/dynamodb/)
- [Kubernetes基礎](https://kubernetes.io/docs/)
- [LocalStack使用方法](https://docs.localstack.cloud/)
- [Rails API開発](https://guides.rubyonrails.org/api_app.html)

## 🤝 コントリビューション

1. フォークを作成
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## 📄 ライセンス

MIT License - 詳細は [LICENSE](LICENSE) ファイルを参照してください。

## 📞 サポート

- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/discussions)

---

**🎯 このプラットフォームで学べること:**
- DynamoDBを使った時系列データ設計
- Kubernetesでのマイクロサービス運用
- LocalStackでのAWS開発環境構築
- Railsでの高性能API開発
- Redisキャッシング戦略
- Docker Composeでの統合環境管理
