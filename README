# Twitter 最近のツイート取得ツール (PowerShell) — 使い方ガイド

## これは何？

指定したTwitterユーザーの最近のツイートを自動で取得してCSVファイルに保存するPowerShellスクリプトです。  
初心者でも使いやすいように、設定や実行手順をわかりやすくまとめています。

---

## 特長

- 複数ユーザーの3日以内のツイートを取得  
- ツイート日時とURLをCSVに保存  
- `.env`ファイルでBearerトークンを安全に管理  
- Twitter APIの制限を考慮した遅延処理あり

---

## 必要なもの

- Windows PC  
- PowerShell（Windows標準搭載のものでOK）  
- Twitter APIのBearerトークン（Twitter開発者アカウントが必要）  
- 本スクリプトおよび関連ファイル

---

## 使い方

### 1. Twitter開発者登録＆Bearerトークン取得

- https://developer.twitter.com にアクセスし開発者登録  
- プロジェクトとアプリを作成  
- 「Bearerトークン」をコピー

### 2. スクリプトファイルをダウンロード

- このリポジトリから `get_recent_tweets.ps1` と `.env.sample` を取得

### 3. `.env`ファイルを作成

- `.env.sample` を `.env` にコピー  
- `.env` にBearerトークンを以下のように記入

```env
BEARER_TOKEN=あなたのBearerトークンをここに貼り付け
