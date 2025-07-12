FROM ruby:3.2.8-slim

# 必要なパッケージのインストール
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    libpq-dev \
    libyaml-dev \
    nodejs \
    npm \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# 作業ディレクトリの設定
WORKDIR /app

# Gemfile をコピー
COPY Gemfile ./

# Bundle インストール
RUN bundle install

# アプリケーションコードをコピー
COPY . .

# ポート3000を公開
EXPOSE 3000

# デフォルトコマンド
CMD ["rails", "server", "-b", "0.0.0.0"]
