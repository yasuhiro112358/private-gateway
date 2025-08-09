#!/bin/bash

# Traefik セットアップスクリプト

echo "Traefik セットアップを開始します..."

# Docker がインストールされているかチェック
if ! command -v docker &> /dev/null; then
    echo "Docker がインストールされていません。Docker をインストールしてください。"
    exit 1
fi

# Docker Compose がインストールされているかチェック
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Docker Compose がインストールされていません。Docker Compose をインストールしてください。"
    exit 1
fi

# acme.json ファイルを作成（Let's Encrypt SSL証明書用）
echo "acme.json ファイルを作成します..."
touch acme.json
chmod 600 acme.json

# Traefik ネットワークを作成
echo "Traefik ネットワークを作成します..."
docker network create traefik 2>/dev/null || echo "Traefik ネットワークは既に存在します。"

# 設定ファイルの検証
echo "設定ファイルを検証します..."
if [ ! -f "traefik.yml" ]; then
    echo "エラー: traefik.yml が見つかりません。"
    exit 1
fi

if [ ! -f "docker-compose.yml" ]; then
    echo "エラー: docker-compose.yml が見つかりません。"
    exit 1
fi

echo "セットアップが完了しました！"
echo ""
echo "使用方法:"
echo "1. traefik.yml の email を設定してください"
echo "2. 以下のコマンドでTraefikを起動: docker-compose up -d"
echo "3. ダッシュボードにアクセス: http://localhost:8080"
echo ""
echo "注意: 本番環境では以下を変更してください:"
echo "- traefik.yml の api.insecure を false に設定"
echo "- 適切な認証を設定"
echo "- ログレベルを ERROR に変更"
