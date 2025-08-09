# private-gateway 手動デプロイ手順（/srv 配下で運用）

目的:
- Traefik を最小構成で導入し、開発/本番のデプロイを手順だけで再現可能にする
- サーバー上では /srv/private-gateway に配置して運用する

前提:
- 対象サーバー: Ubuntu（Docker と Docker Compose が利用可能）
- FQDN: traefik.newtralize.com をサーバーIPに向ける（A/AAAA レコード）
- ファイアウォール: 80/443 を許可

開発（ローカル）
1) プロジェクト直下で起動
   - docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
2) 動作確認
   - ダッシュボード: http://localhost:8080
   - 80番はバックエンド未登録なら404で正常

初回セットアップ（サーバー、/srv 配下）
1) デプロイ先ディレクトリの用意
   - sudo mkdir -p /srv/private-gateway
   - sudo chown $USER: /srv/private-gateway
   - cd /srv/private-gateway
2) リポジトリ取得/更新
   - 初回: git clone git@github.com:yasuhiro112358/private-gateway.git .
   - 以降: git pull
3) 共有ネットワークとボリュームの作成（初回のみ）
   - docker network create traefik
   - docker volume create letsencrypt
   3-確認) 作成確認（存在をチェック）
   - docker network ls | grep -w traefik
   - docker network inspect traefik | head -n 20
   - docker volume ls | grep -w letsencrypt
   - docker volume inspect letsencrypt | head -n 20
4) DNS と FW を確認
   - traefik.newtralize.com の A/AAAA がサーバーIPを指す
   - 80/443 が外部から到達可能

本番デプロイ（Nginx 一時停止で一発導入）
1) 短時間メンテ開始
   - sudo systemctl stop nginx
2) Traefik 起動（本番オーバーライド使用）
   - docker compose -f docker-compose.yml -f docker-compose.prod.yml pull
   - docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
3) 証明書/稼働確認
   - docker compose -f docker-compose.yml -f docker-compose.prod.yml logs -f traefik  # ACME 取得ログを確認
   - https://traefik.newtralize.com にアクセス
4) メンテ終了
   - 既存 Nginx に戻さない場合、そのまま運用
   - 一時復旧が必要な場合は sudo systemctl start nginx

更新手順（本番）
1) cd /srv/private-gateway && git pull
2) docker compose -f docker-compose.yml -f docker-compose.prod.yml pull
3) docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

ロールバック
1) 過去のコミット/タグへ移動: git checkout <commit or tag>
2) 同じ compose コマンドで起動: up -d
3) 最新に戻す: git checkout develop（または main）

Nginx 復旧手順（ロールバック/緊急時）
1) Traefik を停止してポート80/443を開放
   - docker compose -f docker-compose.yml -f docker-compose.prod.yml down
2) Nginx 設定の健全性チェック（任意）
   - sudo nginx -t
3) Nginx を起動（または再起動）
   - 起動: sudo systemctl start nginx
   - 再起動: sudo systemctl restart nginx
4) 状態確認/再読み込み（任意）
   - 状態: sudo systemctl status nginx --no-pager
   - 設定反映のみ: sudo systemctl reload nginx

別スタック（例: phpMyAdmin）を Traefik 経由で公開する
- 別リポ側の Compose で、共有ネットワーク "traefik"（external）に参加させる
- 対象サービスに Traefik 用のラベルを付与してルーティングを定義（例: PathPrefix による /pma 公開）
- ホスト側ポート公開は不要（Traefik 経由で到達）
- 具体的なラベルやルールは別リポ側で管理

運用上の注意
- ダッシュボードは本番で公開されます（現状は無保護）。後で認証やIP制限等の保護を追加することを強く推奨
- 証明書ストレージは Docker の名前付きボリューム letsencrypt に保存（手動作成不要）
- DNS 伝播や FW 設定でアクセスに時間がかかる場合があります

トラブルシュート
- 80/443 を別プロセス（Nginx 等）が使用中: 一時停止してから起動
- 証明書が取得できない: 80 番の到達性、DNS 設定、レートリミットを確認
- 共有ネットワーク未作成: docker network create traefik
