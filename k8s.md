# Kubernetes (K8s) 概要とプロジェクトでの使用方法

## 📋 目次
1. [Kubernetesとは](#kubernetesとは)
2. [このプロジェクトでのKubernetes構成](#このプロジェクトでのkubernetes構成)
3. [Kubernetesマニフェストファイル詳細](#kubernetesマニフェストファイル詳細)
4. [Kubernetes環境のセットアップ](#kubernetes環境のセットアップ)
5. [kubectl コマンド実践例](#kubectl-コマンド実践例)
6. [トラブルシューティング](#トラブルシューティング)
7. [学習リソース](#学習リソース)

## 🚀 Kubernetesとは

Kubernetes（K8s）は、コンテナ化されたアプリケーションの**デプロイ、スケーリング、管理**を自動化するためのオープンソースプラットフォームです。

### 主要な特徴
- **コンテナオーケストレーション**: 複数のコンテナを協調して動作させる
- **自動スケーリング**: 負荷に応じてアプリケーションを自動的にスケール
- **自己修復**: 障害が発生したコンテナを自動的に再起動
- **サービスディスカバリー**: サービス間の通信を自動的に管理
- **ローリングアップデート**: ダウンタイムなしでアプリケーションを更新

### 基本概念
- **Pod**: 1つ以上のコンテナをグループ化した最小デプロイメント単位
- **Service**: Podへのネットワークアクセスを提供
- **Deployment**: Podの作成・更新・削除を管理
- **ConfigMap**: 設定データを管理
- **Secret**: 機密データ（パスワード、トークンなど）を管理
- **Namespace**: リソースを論理的に分離

## 🏗️ このプロジェクトでのKubernetes構成

このIoTデータ収集・分析プラットフォームでは、以下のサービスをKubernetesで管理しています：

```
┌─────────────────────────────────────────────────────────────┐
│                    iot-platform namespace                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Rails App   │  │ Sidekiq     │  │ LocalStack  │         │
│  │ (2 replicas)│  │ (1 replica) │  │ (1 replica) │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐                          │
│  │ PostgreSQL  │  │ Redis       │                          │
│  │ (1 replica) │  │ (1 replica) │                          │
│  └─────────────┘  └─────────────┘                          │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐                          │
│  │ ConfigMap   │  │ Secret      │                          │
│  │ (設定管理)   │  │ (機密情報)   │                          │
│  └─────────────┘  └─────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

### サービス構成
1. **Rails Application** (rails-app)
   - メインAPIサーバー
   - レプリカ数: 2
   - ポート: 3000

2. **Sidekiq** (sidekiq)
   - バックグラウンドジョブ処理
   - レプリカ数: 1

3. **LocalStack** (localstack)
   - AWS サービスエミュレーション
   - DynamoDB、S3、SNS、SQS
   - ポート: 4566

4. **PostgreSQL** (postgres)
   - メタデータストレージ
   - ポート: 5432

5. **Redis** (redis)
   - キャッシュ・セッション管理
   - ポート: 6379

## 📁 Kubernetesマニフェストファイル詳細

### 1. Namespace (`k8s/namespace.yaml`)
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: iot-platform
  labels:
    name: iot-platform
    environment: development
    purpose: iot-data-collection
```

### 2. ConfigMap (`k8s/configmap.yaml`)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: iot-platform-config
  namespace: iot-platform
data:
  RAILS_ENV: "development"
  DATABASE_HOST: "postgres-service"
  REDIS_URL: "redis://redis-service:6379/0"
  AWS_ENDPOINT: "http://localstack-service:4566"
  # その他の設定...
```

### 3. Secret (`k8s/secret.yaml`)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: iot-platform-secret
  namespace: iot-platform
type: Opaque
data:
  # Base64エンコードされた機密情報
  DATABASE_PASSWORD: cG9zdGdyZXM=
  AWS_ACCESS_KEY_ID: dGVzdA==
  AWS_SECRET_ACCESS_KEY: dGVzdA==
```

### 4. Deployments (`k8s/deployments.yaml`)
主要なDeploymentリソース：
- **Rails App**: 2レプリカ、ヘルスチェック付き
- **Sidekiq**: バックグラウンドジョブ処理
- **LocalStack**: AWS サービスエミュレーション
- **PostgreSQL**: データベース
- **Redis**: キャッシュサーバー

### 5. Services (`k8s/services.yaml`)
各Podへのネットワークアクセスを提供：
- **rails-app-service**: LoadBalancer (外部アクセス)
- **rails-app-nodeport**: NodePort (開発用)
- **postgres-service**: ClusterIP (内部通信)
- **redis-service**: ClusterIP (内部通信)
- **localstack-service**: ClusterIP (内部通信)

## 🛠️ Kubernetes環境のセットアップ

### 1. 前提条件のインストール

```bash
# macOS (Homebrew使用)
brew install kubectl
brew install minikube

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### 2. Minikubeクラスターの起動

```bash
# Minikubeクラスター起動
minikube start --driver=docker --memory=4096 --cpus=2

# クラスター状態確認
minikube status

# Kubernetesダッシュボード起動（オプション）
minikube dashboard
```

### 3. Dockerイメージのビルド

```bash
# Railsアプリケーションのイメージをビルド
docker build -t iot-platform:latest .

# MinikubeのDockerデーモンを使用
eval $(minikube docker-env)
docker build -t iot-platform:latest .
```

### 4. Kubernetesリソースのデプロイ

```bash
# 名前空間作成
kubectl apply -f k8s/namespace.yaml

# 設定ファイル適用
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

# サービスとデプロイメント適用
kubectl apply -f k8s/services.yaml
kubectl apply -f k8s/deployments.yaml

# 全リソースを一括適用
kubectl apply -f k8s/
```

## 🔧 kubectl コマンド実践例

### 基本的なリソース確認

```bash
# 名前空間の確認
kubectl get namespaces

# 特定の名前空間のPod一覧
kubectl get pods -n iot-platform

# 全リソースの状態確認
kubectl get all -n iot-platform

# サービス一覧
kubectl get services -n iot-platform

# デプロイメント一覧
kubectl get deployments -n iot-platform
```

### 詳細情報の確認

```bash
# Pod詳細情報
kubectl describe pod <pod-name> -n iot-platform

# サービス詳細情報
kubectl describe service rails-app-service -n iot-platform

# デプロイメント詳細情報
kubectl describe deployment rails-app -n iot-platform

# ConfigMap詳細情報
kubectl describe configmap iot-platform-config -n iot-platform

# Secret詳細情報
kubectl describe secret iot-platform-secret -n iot-platform
```

### ログの確認

```bash
# 特定のPodのログ
kubectl logs <pod-name> -n iot-platform

# デプロイメントのログ（最新のPod）
kubectl logs deployment/rails-app -n iot-platform

# リアルタイムログ監視
kubectl logs -f deployment/rails-app -n iot-platform

# 複数コンテナがある場合
kubectl logs <pod-name> -c <container-name> -n iot-platform
```

### Pod内でのコマンド実行

```bash
# Pod内でbashを実行
kubectl exec -it <pod-name> -n iot-platform -- bash

# Rails コンソール
kubectl exec -it <rails-pod-name> -n iot-platform -- rails console

# データベースマイグレーション
kubectl exec -it <rails-pod-name> -n iot-platform -- rails db:migrate

# 特定のコマンド実行
kubectl exec <pod-name> -n iot-platform -- ls -la
```

### スケーリング操作

```bash
# レプリカ数を変更
kubectl scale deployment rails-app --replicas=3 -n iot-platform

# 自動スケーリング設定
kubectl autoscale deployment rails-app --min=2 --max=10 --cpu-percent=80 -n iot-platform

# スケーリング状態確認
kubectl get hpa -n iot-platform
```

### ローリングアップデート

```bash
# イメージの更新
kubectl set image deployment/rails-app rails=iot-platform:v2.0 -n iot-platform

# ロールアウト状態確認
kubectl rollout status deployment/rails-app -n iot-platform

# ロールアウト履歴確認
kubectl rollout history deployment/rails-app -n iot-platform

# 前のバージョンにロールバック
kubectl rollout undo deployment/rails-app -n iot-platform
```

### ポートフォワーディング

```bash
# Rails アプリケーションへのアクセス
kubectl port-forward service/rails-app-service 3000:3000 -n iot-platform

# PostgreSQLへの直接アクセス
kubectl port-forward service/postgres-service 5432:5432 -n iot-platform

# Redisへの直接アクセス
kubectl port-forward service/redis-service 6379:6379 -n iot-platform

# LocalStackへのアクセス
kubectl port-forward service/localstack-service 4566:4566 -n iot-platform
```

### リソースの削除

```bash
# 特定のPodを削除
kubectl delete pod <pod-name> -n iot-platform

# デプロイメントを削除
kubectl delete deployment rails-app -n iot-platform

# サービスを削除
kubectl delete service rails-app-service -n iot-platform

# 名前空間内の全リソースを削除
kubectl delete all --all -n iot-platform

# 名前空間ごと削除
kubectl delete namespace iot-platform
```

## 🧪 実際のテスト手順

### 1. 環境構築とデプロイ

```bash
# 1. Minikubeクラスター起動
minikube start --driver=docker --memory=4096 --cpus=2

# 2. Dockerイメージビルド
eval $(minikube docker-env)
docker build -t iot-platform:latest .

# 3. Kubernetesリソースデプロイ
kubectl apply -f k8s/

# 4. Pod起動確認
kubectl get pods -n iot-platform -w
```

### 2. アプリケーションテスト

```bash
# 1. Rails アプリケーションへのアクセス
kubectl port-forward service/rails-app-service 3000:3000 -n iot-platform &

# 2. ヘルスチェック
curl http://localhost:3000/health

# 3. API テスト
curl http://localhost:3000/api/v1/devices

# 4. データベース接続テスト
kubectl exec -it deployment/rails-app -n iot-platform -- rails db:version
```

### 3. スケーリングテスト

```bash
# 1. 現在のレプリカ数確認
kubectl get deployment rails-app -n iot-platform

# 2. スケールアップ
kubectl scale deployment rails-app --replicas=3 -n iot-platform

# 3. Pod数確認
kubectl get pods -n iot-platform | grep rails-app

# 4. 負荷分散確認
for i in {1..10}; do curl http://localhost:3000/health; done
```

### 4. ログ監視テスト

```bash
# 1. リアルタイムログ監視
kubectl logs -f deployment/rails-app -n iot-platform

# 2. 複数Podのログ監視
kubectl logs -f deployment/rails-app -n iot-platform --all-containers=true

# 3. エラーログフィルタリング
kubectl logs deployment/rails-app -n iot-platform | grep ERROR
```

## 🚨 トラブルシューティング

### よくある問題と解決方法

#### 1. Podが起動しない
```bash
# Pod状態確認
kubectl get pods -n iot-platform

# Pod詳細情報確認
kubectl describe pod <pod-name> -n iot-platform

# Pod イベント確認
kubectl get events -n iot-platform --sort-by=.metadata.creationTimestamp
```

#### 2. イメージプルエラー
```bash
# Minikubeのdocker環境を使用
eval $(minikube docker-env)

# イメージ再ビルド
docker build -t iot-platform:latest .

# イメージ一覧確認
docker images | grep iot-platform
```

#### 3. サービス接続エラー
```bash
# サービス詳細確認
kubectl describe service <service-name> -n iot-platform

# エンドポイント確認
kubectl get endpoints -n iot-platform

# ポートフォワーディングテスト
kubectl port-forward service/<service-name> <local-port>:<service-port> -n iot-platform
```

#### 4. リソース不足
```bash
# ノードリソース確認
kubectl top nodes

# Pod リソース使用量確認
kubectl top pods -n iot-platform

# Minikubeリソース追加
minikube stop
minikube start --memory=8192 --cpus=4
```

### デバッグ用コマンド

```bash
# クラスター情報
kubectl cluster-info

# ノード情報
kubectl get nodes -o wide

# 全名前空間のリソース確認
kubectl get all --all-namespaces

# リソース使用量確認
kubectl top nodes
kubectl top pods --all-namespaces

# Kubernetesバージョン確認
kubectl version
```

## 📚 学習リソース

### 公式ドキュメント
- [Kubernetes公式ドキュメント](https://kubernetes.io/docs/)
- [kubectl チートシート](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Minikube公式ドキュメント](https://minikube.sigs.k8s.io/docs/)

### 学習コンテンツ
- [Kubernetes基礎コース](https://kubernetes.io/training/)
- [Play with Kubernetes](https://labs.play-with-k8s.com/)
- [Katacoda Kubernetes Scenarios](https://www.katacoda.com/courses/kubernetes)

### 実践的な学習
1. **このプロジェクトでの実践**
   - 異なるレプリカ数でのテスト
   - ローリングアップデートの実行
   - 障害シミュレーション

2. **追加の学習項目**
   - Ingress Controller
   - Persistent Volume
   - Network Policies
   - RBAC (Role-Based Access Control)

## 🎯 次のステップ

1. **基本操作の習得**
   - kubectl コマンドの練習
   - リソースの作成・更新・削除

2. **高度な機能の学習**
   - Helm パッケージマネージャー
   - Prometheus + Grafana による監視
   - Istio サービスメッシュ

3. **本番環境への適用**
   - EKS、GKE、AKS での運用
   - CI/CD パイプライン構築
   - セキュリティ強化

---

このドキュメントを参考に、Kubernetesの基本概念から実践的な運用まで段階的に学習を進めてください。質問や問題が発生した場合は、トラブルシューティングセクションを参照するか、公式ドキュメントを確認してください。
