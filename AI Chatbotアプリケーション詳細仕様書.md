---
marp: true
style: |
  section {
    background: linear-gradient(to right, #ffffff, #e0f7fa);
    color: #333333;
    padding: 30px;
  }

  section h1 {
    font-size: 48px;
    margin-bottom: 20px;
    color: #00796b;
  }

  section h2 {
    font-size: 38px;
    margin-bottom: 15px;
    color: #004d40;
    position: absolute;
    top: 20px;
    left: 30px;
    right: 30px;
    border-bottom: 2px solid #004d40;
    padding-bottom: 10px;
  }

  section h3 {
    font-size: 28px;
    color: #00695c;
    margin-top: 100px;
  }

  section p, section li {
    font-size: 20px;
    line-height: 1.6;
  }

  section.database ul {
    font-size: 16px;
    line-height: 1.4;
    margin-top: 20px;
  }

  section.title {
    background: linear-gradient(135deg, #e0f7fa, #b2ebf2);
    text-align: center;
    color: #004d40;
  }

  section.title h1 {
    font-size: 60px;
    margin-bottom: 20px;
  }

  section.title h3 {
    font-size: 32px;
    color: #00796b;
  }

  footer {
    position: absolute;
    bottom: 10px;
    right: 30px;
    font-size: 16px;
    color: #00796b;
  }
---

<!-- _class: title -->

# AI Chatbotアプリケーション詳細仕様書

### Fusion Mind 株式会社

<footer>2024/12/02</footer>

---

## 目次

1. アプリケーション概要
2. 認証システム
3. チャットシステム
4. 決済システム
5. リアルタイム通信
6. データベース構造
7. 環境設定
8. UIデザイン

---

## 1. アプリケーション概要

### 概要
AI Chatbotは、OpenAIのGPTモデルを活用した、モバイル専用のチャットアプリケーションです。
無料プランと有料プランを提供し、ユーザーは好みのAIモデルを選択して対話を行うことができます。
複数のチャットを作成・管理でき、各チャットの内容に応じて自動でタイトルが生成されます。
ストリーミング形式でのレスポンスにより、スムーズな会話体験を実現しています。

主な特徴：
- Android対応（iOS対応予定）のモバイル専用アプリ
- 複数のGPTモデル選択が可能（プラン別）
- Stripeによる安全な月額課金システム
- チャット履歴のローカル保存
- マルチチャット管理機能

---

## 2. 認証システム

### パスワード管理
- ハッシュ化：passlib.hashライブラリ使用（PBKDF2-SHA256）
- パスワード要件：
  * 8～16文字
  * アルファベットと数字を含む
  * スペース禁止
- パスワードリセット：
  * メールによるリセットリンク
  * リンク有効期限：60分
  * HTMLメール形式

---
## 2. 認証システム

### アカウントロック機構
- 試行回数管理：login_attemptsカラム
- ロック条件：3回連続失敗【要検討】
- ロック解除：
  * メールによる解除リンク
  * URLSafeTimedSerializer使用
  * リンク有効期限：60分

---
## 2. 認証システム

### セキュアストレージ
- ライブラリ：flutter_secure_storage
- 保存情報：
  * メールアドレス
  * ハッシュ化パスワード
  * ログイン日時
  * 認証タイプ
  * ログイン保持期間：デバッグ用15分（設定可能）【要検討】

---
## 2. 認証システム

### Google認証
- ライブラリ：google_sign_in
- 取得情報：email, profile
- ログイン状態保持オプション
- 既存アカウントとの連携機能

---

## 3. チャットシステム

### OpenAI連携
- 利用可能モデル：
  * GPT-3.5 Turbo（Freeプラン/Standardプラン）
  * GPT-4o（Standardプラン）
  * GPT-4o mini（Standardプラン）
- タイムアウト：60秒
- ストリーミングレスポンス対応

---
## 3. チャットシステム


### チャット管理
- SQLiteによるローカル保存
- 会話履歴の認識
- オプションで設定したユーザーネームを認識
- チャットタイトル：
  * 初回メッセージから自動生成
  * タイトル生成にGPT-3.5 Turbo使用
  * 20文字以内
  * 任意のタイトルに変更可
- メッセージ制限：
  * 入力上限：200文字【要検討】
  * 履歴保持：1000文字【要検討】

---
## 3. チャットシステム


### 表示・操作
- LINE風UIデザイン(黄緑色を基調としたchatUI)
- 自動スクロール
- ソート機能：
  * 作成日時（昇順/降順）
  * 更新日時（昇順/降順）
- チャット削除機能
- 注意書き表示：'この応答には誤りが含まれる可能性があります。'

---
## 3. チャットシステム


### トークンコスト計算【要検討】
チャット内容からトークン数を計算し、モデルごとのレートを考慮してコストを算出するロジック。

**目的**
- コスト管理
- カラム連携

**現状**
- 仕様変更により未使用。
- 将来的な制御のため保持。

---

## 4. 決済システム

### Stripe連携
- 決済処理：
  * クレジットカードトークン化
  * PaymentSheet使用
  * 自動継続課金
- 顧客管理：customer_idで管理
- エラーハンドリング：
  * 決済失敗時の自動プラン変更
  * トランザクション管理

---
## 4. 決済システム

### プラン管理
- Freeプラン：GPT-3.5 Turbo
- Standardプラン：全モデル利用可能
- 解約処理：自動Freeプラン移行
- 支払い履歴：履歴表示機能

---

## 5. リアルタイム通信

### WebSocket実装
- ライブラリ：Flask-SocketIO / socket_io_client
- 通知イベント：
  * プラン変更
  * 決済状態
- 使用用途：リアルタイムUI反映

---

## 6. データベース構造

###  PostgreSQL（サーバーサイド）

#### user_accountテーブル

- **email (PK)**：ユーザー識別用メールアドレス
- **username**：登録時のユーザー名【要検討】
- **password_hash**：パスワードのハッシュ値（PBKDF2-SHA256使用）
- **plan**：契約プラン（'Free'/'Standard'）
- **monthly_cost**：月間使用コスト（トークン計算用・現状未使用）【要検討】
- **created_at**：アカウント作成日時（default: CURRENT_TIMESTAMP）
- **last_login**：成功したログインの最終日時
- **login_attempts**：連続ログイン失敗回数（3回でロック、default: 0）
- **last_attempt_time**：失敗したログイン試行の最終時刻（ロック管理用）

---
## 6. データベース構造

- **unlock_token**：アカウントロック解除用トークン
- **user_name**：プロンプト用ユーザー名：AIに認識を与える名前、オプション画面で設定可能
- **isdarkmode**：ダークモード設定（default: false）true：ダーク/false：ライト
- **selectedmodel**：使用AIモデル（default: 'gpt-3.5-turbo'）、プランによって制限
- **chat_history_max_length**：チャット履歴文字数制限（default: 1000）ユーザー毎に管理する場合利用【要検討】
- **input_text_length**：入力文字数制限（default: 200）、ユーザー毎に管理する場合利用【要検討】
- **sortorder**：チャット一覧ソート順（default: 'created_at ASC'）
- **next_process_date**：次回処理予定日、サブスクリプション処理で使用
- **next_process_type**：処理タイプ（'payment'/'cancel'）、サブスクリプション処理で使用
- **customer_id**：Stripe顧客ID、サブスクリプション処理で使用


---

## 6. データベース構造

###  PostgreSQL（サーバーサイド）


#### user_paymentテーブル
- **id (PK)**：支払い記録ID（連番）
- **email (FK)**：user_accountテーブルの外部キー
- **processed_date**：処理実行日時（default: NOW()）
- **plan**：処理時点のプラン種別
- **amount**：決済金額
- **transaction_id**：Stripeトランザクション識別子
- **message**：処理内容の説明文
- **created_at**：レコード作成日時（default: NOW()）
- **updated_at**：レコード更新日時（default: NOW()）
- **processed_by**：処理区分（'payment'/'auto_cancellation'/'auto_subscription'）

---

## 6. データベース構造

###  SQLite（ローカル）


#### chatテーブル
- **id (PK)**：メッセージID（連番）
- **chat_id**：チャットグループID
- **content**：メッセージ内容
- **timestamp**：メッセージ送信日時
- **is_user**：送信者種別（1:ユーザー、0:AI）
- **response_to_message_id**：返信元メッセージID（AIの返信時に使用）

---

## 6. データベース構造

###  SQLite（ローカル）


#### select_chatテーブル
- **id (PK)**：チャットグループID（連番）
- **title**：チャットタイトル
- **created_at**：作成日時
- **updated_at**：最終更新日時


---

## 7. 環境設定
* 必要環境変数：
  * サーバー設定（URL、ポート）
  * データベース接続情報
  * API キー（OpenAI、Stripe）
  * メールサーバー設定
  * Google OAuth設定
  * セキュリティ設定

---

## 8. UIデザイン

### 基本デザイン
- LINE風のチャットインターフェース
- 黄緑色を基調としたカラースキーム
- アプリ全体で統一されたデザインパターン
- 直感的な操作性を重視したレイアウト

---
## 8. UIデザイン

### テーマ設定
- ダークモード/ライトモード切り替え
- ユーザー設定として保存
- アプリ再起動時に設定を維持
- システムテーマとの連動（オプション）

---
## 8. UIデザイン

### 画面構成
- ヘッダー：タイトル、設定メニュー
- チャット一覧：ソート機能、削除機能
- チャット画面：メッセージ入力欄、送信ボタン
- 設定画面：ユーザー名設定、テーマ切り
