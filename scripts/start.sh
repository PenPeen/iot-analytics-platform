#!/bin/bash

# IoTデータ収集・分析プラットフォーム起動スクリプト

set -e

echo "🚀 IoTデータ収集・分析プラットフォームを起動中..."

# 色付きメッセージ用の関数
print_success() {
    echo -e "\033[32m✅ $1\033[0m"
}

print_error() {
    echo -e "\033[31m❌ $1\033[0m"
}

print_info() {
    echo -e "\033[34mℹ️  $1\033[0m"
}

print_warning() {
    echo -e "\033[33m⚠️  $1\033[0m"
}

# 前提条件のチェック
check_prerequisites() {
    print_info "前提条件をチェック中..."

    if ! command -v docker &> /dev/null; then
        print_error "Dockerがインストールされていません"
        exit 1
    fi

    if ! command -v docker compose &> /dev/null; then
        print_error "Docker Composeがインストールされていません"
        exit 1
    fi

    print_success "前提条件チェック完了"
}

# 環境設定ファイルの確認
check_env_files() {
    print_info "環境設定ファイルをチェック中..."

    if [ ! -f .env ]; then
        if [ -f env.example ]; then
            print_warning ".envファイルが見つかりません。env.exampleからコピーします..."
            cp env.example .env
            print_success ".envファイルを作成しました"
        else
            print_error ".envファイルとenv.exampleファイルが見つかりません"
            exit 1
        fi
    fi

    print_success "環境設定ファイルチェック完了"
}

# LocalStackディレクトリの作成
create_localstack_dir() {
    print_info "LocalStackデータディレクトリを作成中..."
    mkdir -p localstack/data
    print_success "LocalStackディレクトリ作成完了"
}

# Docker Composeでサービス起動
start_services() {
    print_info "Dockerサービスを起動中..."

    # 既存のコンテナを停止・削除
    docker compose down --remove-orphans 2>/dev/null || true

    # サービスを起動
    docker compose up -d

    print_success "Dockerサービス起動完了"
}

# サービスの健全性チェック
check_services_health() {
    print_info "サービスの健全性をチェック中..."

    # LocalStackの起動を待機
    print_info "LocalStackの起動を待機中..."
    sleep 10

    max_attempts=30
    attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:4566/health > /dev/null 2>&1; then
            print_success "LocalStack起動確認"
            break
        fi

        if [ $attempt -eq $max_attempts ]; then
            print_error "LocalStackの起動に失敗しました"
            docker compose logs localstack
            exit 1
        fi

        print_info "LocalStack起動待機中... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done

    # Redisの健全性チェック
    if docker compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        print_success "Redis接続確認"
    else
        print_warning "Redis接続に問題があります"
    fi

    # PostgreSQLの健全性チェック
    if docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
        print_success "PostgreSQL接続確認"
    else
        print_warning "PostgreSQL接続に問題があります"
    fi
}

# データベースのセットアップ
setup_database() {
    print_info "データベースをセットアップ中..."

    # PostgreSQLデータベースの作成とマイグレーション
    docker compose exec -T rails rails db:create db:migrate 2>/dev/null || {
        print_warning "データベース作成/マイグレーションでエラーが発生しました（既に存在する可能性があります）"
    }

    print_success "データベースセットアップ完了"
}

# サンプルデータの投入
seed_sample_data() {
    print_info "サンプルデータを投入中..."

    docker compose exec -T rails rails db:seed || {
        print_warning "サンプルデータ投入でエラーが発生しました"
    }

    print_success "サンプルデータ投入完了"
}

# アプリケーション情報の表示
show_application_info() {
    echo ""
    echo "🎉 IoTデータ収集・分析プラットフォームが起動しました！"
    echo ""
    echo "📋 サービス情報:"
    echo "  🌐 Rails API: http://localhost:3000"
    echo "  ❤️  ヘルスチェック: http://localhost:3000/health"
    echo "  📊 LocalStack: http://localhost:4566"
    echo "  🔧 Redis: localhost:6379"
    echo "  🐘 PostgreSQL: localhost:5432"
    echo ""
    echo "📖 API エンドポイント例:"
    echo "  GET  /api/v1/devices              - デバイス一覧"
    echo "  POST /api/v1/devices              - デバイス作成"
    echo "  GET  /api/v1/devices/:id/sensor_data - センサーデータ取得"
    echo "  POST /api/v1/devices/:id/sensor_data - センサーデータ投入"
    echo ""
    echo "🛠️  管理コマンド:"
    echo "  docker compose logs -f            - ログ確認"
    echo "  docker compose exec rails bash    - Railsコンテナ接続"
    echo "  docker compose down               - サービス停止"
    echo ""
    echo "📚 詳細はREADME.mdを参照してください"
}

# メイン実行
main() {
    check_prerequisites
    check_env_files
    create_localstack_dir
    start_services
    check_services_health
    setup_database
    seed_sample_data
    show_application_info
}

# スクリプト実行
main "$@"
