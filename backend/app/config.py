# config.py
import os
from dotenv import load_dotenv

# .envファイルの読み込み
load_dotenv()

class Config:


    # Google OAuth設定
    GOOGLE_CLIENT_ID = os.getenv('GOOGLE_CLIENT_ID')
    
    @staticmethod
    def init_google_auth():
        if not Config.GOOGLE_CLIENT_ID:
            raise ValueError("GOOGLE_CLIENT_ID is not set")


    # 環境設定（デフォルトはdevelopment）
    ENVIRONMENT = os.getenv('FLASK_ENV', 'development')
    
    # インターバル設定
    SCHEDULER_INTERVAL = int(os.getenv('SCHEDULER_INTERVAL'))
    PROCESS_INTERVAL = os.getenv('PROCESS_INTERVAL')
    
    @staticmethod
    def get_scheduler_interval():
        """スケジューラーの実行間隔を返す"""
        return Config.SCHEDULER_INTERVAL

    @staticmethod
    def get_next_process_interval():
        """次回処理日までの間隔を返す"""
        return Config.PROCESS_INTERVAL
        

    # Flask設定
    SECRET_KEY = os.getenv('SECRET_KEY')
    
    # データベース設定
    DB_HOST = os.getenv('DB_HOST')
    DB_NAME = os.getenv('DB_NAME')
    DB_USER = os.getenv('DB_USER')
    DB_PASSWORD = os.getenv('DB_PASSWORD')
    
    # Stripe設定
    STRIPE_SECRET_KEY = os.getenv('STRIPE_SECRET_KEY')
    WEBHOOK_SECRET_KEY = os.getenv('WEBHOOK_SECRET_KEY')
    
    # メール設定
    MAIL_SERVER = os.getenv('MAIL_SERVER')
    MAIL_PORT = int(os.getenv('MAIL_PORT'))
    MAIL_USE_TLS = os.getenv('MAIL_USE_TLS') == 'True'
    MAIL_USERNAME = os.getenv('MAIL_USERNAME')
    MAIL_PASSWORD = os.getenv('MAIL_PASSWORD')

    
    # ユーザー認証設定
    MAX_LOGIN_ATTEMPTS = int(os.getenv('MAX_LOGIN_ATTEMPTS'))
    LOCKOUT_TIME = int(os.getenv('LOCKOUT_TIME'))  # ロックアウト時間（分）
    PASSWORD_RESET_TIMEOUT = int(os.getenv('PASSWORD_RESET_TIMEOUT'))  # パスワードリセットの有効期間（秒）

    
    # サブスクリプション設定
    SUBSCRIPTION_PLANS = {
        'Free': {'price': int(os.getenv('SUBSCRIPTION_FREE_PRICE'))},
        'Standard': {'price': int(os.getenv('SUBSCRIPTION_STANDARD_PRICE'))},
    }
    
    # トークン設定
    DEFAULT_INPUT_LENGTH = 200
    DEFAULT_HISTORY_LENGTH = 1000
    DEFAULT_SORT_ORDER = 'created_at ASC'
    
    # APIモデル設定
    AVAILABLE_MODELS = [
        'gpt-4',
        'gpt-3.5-turbo',
        'gpt-4o-mini'
    ]
    DEFAULT_MODEL = 'gpt-3.5-turbo'

class DevelopmentConfig(Config):
    DEBUG = True
    TESTING = False

class TestingConfig(Config):
    DEBUG = True
    TESTING = True

class ProductionConfig(Config):
    DEBUG = False
    TESTING = False

# 環境に応じた設定の選択
config = {
    'development': DevelopmentConfig,
    'testing': TestingConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}