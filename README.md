# IoTデータ収集・分析プラットフォーム

Rails + DynamoDB（Dynamoid） + Kubernetes + Redis + LocalStack + Terraform を使用した本格的なIoTデータ収集・分析プラットフォームです。

## 🌟 概要

センサーデータの大量書き込みにDynamoDBを活用し、デバイス管理とデータ可視化をRailsで構築した学習目的のプラットフォームです。LocalStackによる完全ローカル開発環境、Kubernetesでのコンテナオーケストレーション、Redisキャッシング、Sidekiqによる非同期処理を統合しています。

![メインダッシュボード](images/dashboard_main.png)

**主な機能:**
- 5台のIoTデバイスの状態監視
- 時系列センサーデータの可視化（温度、湿度、気圧など）
- システムヘルス監視（DynamoDB、Redis、PostgreSQL）
- リアルタイム更新（30秒間隔）
- レスポンシブデザイン

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
                   │ Unleash      │               │
                   │ (Feature     │               │
                   │  Flags)      │               │
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
- **Feature Flags**: Unleash
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

### 🔧 Feature Flags (Unleash)
- **URL**: http://localhost:4242
- **管理画面**: Feature Flagsの作成・管理
- **A/Bテスト**: 段階的機能リリース
- **ユーザーセグメント**: 特定ユーザーへの機能提供
- **リアルタイム切り替え**: 再デプロイ不要の機能制御

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

# Unleash初期設定
echo "Unleash管理画面にアクセス: http://localhost:4242"
echo "初期ログイン: admin / unleash4all"

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
| **Unleash** | http://localhost:4242 | Feature Flags管理 |
| **LocalStack** | http://localhost:4566 | AWS サービスエミュレーション |
| **Redis** | localhost:6379 | キャッシュサーバー |
| **PostgreSQL** | localhost:5432 | データベース |
| **PostgreSQL (Unleash)** | localhost:5433 | Unleash専用データベース |

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

### Feature Flags
```bash
# 全Feature Flagsの状態取得
GET /api/feature_flags

# 特定Feature Flagの状態取得
GET /api/feature_flags/:name

# コンテキスト付きFeature Flag確認
GET /api/feature_flags/:name?user_id=123&context[device_type]=sensor
```

## 🚩 Feature Flags (Unleash)

### 初期設定

```bash
# Unleash管理画面にアクセス
open http://localhost:4242

# 初期ログイン情報
Username: admin
Password: unleash4all
```

### Feature Flagsの例

```ruby
# Railsアプリケーションでの使用例

# 1. 新しいダッシュボード機能の段階的リリース
if unleash.is_enabled?("new_dashboard_ui", user_id: current_user.id)
  render :new_dashboard
else
  render :legacy_dashboard
end

# 2. 高度な分析機能の制御
if unleash.is_enabled?("advanced_analytics")
  perform_advanced_analysis
end

# 3. デバイス別機能の制御
if unleash.is_enabled?("device_specific_features",
                      context: { device_type: device.device_type })
  enable_device_specific_features
end
```

### 推奨Feature Flags

| Flag名 | 説明 | 用途 |
|--------|------|------|
| `new_dashboard_ui` | 新しいダッシュボードUI | 段階的UI更新 |
| `advanced_analytics` | 高度な分析機能 | 機能のA/Bテスト |
| `real_time_alerts` | リアルタイムアラート | 負荷制御 |
| `device_management_v2` | デバイス管理v2 | 新機能のカナリアリリース |
| `experimental_features` | 実験的機能 | 開発者向け機能 |

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

## 🔧 トラブルシューティング

### よくある問題と解決方法

#### 1. データの読み込みに失敗する

**症状**: ダッシュボードで「データの読み込みに失敗しました」と表示される

**原因**: DynamoDBテーブルが存在しない、またはサービス間の接続エラー

**解決方法**:
```bash
# 1. LocalStackとDynamoDBの状態確認
docker-compose logs localstack

# 2. DynamoDBテーブルの作成
docker-compose exec rails bin/rails db:seed

# 3. サービスの再起動
docker-compose restart
```

#### 2. Redis接続エラー

**症状**: システムヘルスでRedisが「Connected」にならない

**原因**: Redis接続設定の問題

**解決方法**:
```bash
# Redis接続確認
docker-compose exec redis redis-cli ping

# 環境変数確認
docker-compose exec rails env | grep REDIS_URL
```

#### 3. コンテナが起動しない

**症状**: `docker-compose up -d`でエラーが発生

**解決方法**:
```bash
# 既存のコンテナとボリュームを削除
docker-compose down -v

# イメージの再ビルド
docker-compose build --no-cache

# 再起動
docker-compose up -d
```

#### 4. LocalStackが応答しない

**症状**: LocalStackのヘルスチェックが失敗する

**解決方法**:
```bash
# LocalStackの状態確認
curl http://localhost:4566/health

# LocalStackの再起動
docker-compose restart localstack

# ログ確認
docker-compose logs -f localstack
```

#### 5. Unleashが起動しない

**症状**: Unleash管理画面にアクセスできない

**原因**: PostgreSQL接続エラー、またはポート競合

**解決方法**:
```bash
# Unleash用PostgreSQLの状態確認
docker-compose logs postgres_unleash

# Unleashサービスの状態確認
docker-compose logs unleash

# ポート確認
lsof -i :4242

# Unleashサービスの再起動
docker-compose restart unleash
```

#### 6. Feature Flagsが反映されない

**症状**: Railsアプリケーションでfeature flagsが動作しない

**原因**: API Token設定エラー、またはネットワーク接続問題

**解決方法**:
```bash
# Unleash API接続確認
curl -H "Authorization: default:development.unleash-insecure-api-token" \
     http://localhost:4242/api/client/features

# Rails環境変数確認
docker-compose exec rails env | grep UNLEASH

# Unleash接続テスト
docker-compose exec rails bin/rails runner "puts Unleash.is_enabled?('test')"
```

## 📝 更新履歴

### 2025-07-13
- **新機能**: Unleash Feature Flagsの追加
  - Docker ComposeにUnleashサービスを追加
  - Unleash専用PostgreSQLデータベースの設定
  - Rails/SidekiqでのUnleash環境変数設定
  - Feature Flagsの使用例とベストプラクティス追加
  - トラブルシューティングガイドの更新
- **修正**: Redis接続エラーの解決
  - `dashboard_controller.rb`でRedis接続方法を修正
  - `Rails.cache.redis.ping`から`Redis.new().ping`に変更
- **改善**: 温度トレンドチャートの下にマージン追加
  - CSSで`margin-bottom: 2rem`を追加
  - レイアウトの見栄えを改善
- **機能追加**: README.mdにスクリーンショットセクション追加
  - メインダッシュボードのスクリーンショット
  - ヘルスチェックAPIのスクリーンショット
  - デバイス管理APIのスクリーンショット

### 初期リリース
- IoTデータ収集・分析プラットフォームの基本機能実装
- DynamoDB + LocalStack環境構築
- Rails APIとWebダッシュボード実装
- Docker Compose環境構築
- Kubernetes設定ファイル作成
- Terraform設定ファイル作成

## 🤝 貢献

このプロジェクトは学習目的で作成されています。改善提案やバグ報告は歓迎します。

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 📞 サポート

質問やサポートが必要な場合は、GitHubのIssuesをご利用ください。
