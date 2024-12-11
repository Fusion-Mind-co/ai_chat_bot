# app/services/auth.py
from datetime import datetime, timedelta
from passlib.hash import pbkdf2_sha256
from ..database import execute_query
from ..config import Config 
from ..database import get_db_connection
import os
from google.oauth2 import id_token
from google.auth.transport import requests
from ..services.email import EmailService
from itsdangerous import URLSafeTimedSerializer 

# シリアライザーの初期化
s = URLSafeTimedSerializer(Config.SECRET_KEY)  

class AuthService:
    @staticmethod
    def verify_google_token(token: str) -> dict:
        """Googleトークンを検証し、ユーザー情報を取得"""
        try:
            idinfo = id_token.verify_oauth2_token(
                token,
                requests.Request(),
                Config.GOOGLE_CLIENT_ID
            )
            return idinfo
        except Exception as e:
            print(f"Googleトークン検証エラー: {e}")
            raise

    @staticmethod
    def signup(email: str, username: str, password: str, plan: str = 'Free') -> tuple[bool, str]:
        try:
            # パスワードのハッシュ化
            hashed_password = pbkdf2_sha256.hash(password)
            current_time = datetime.now()
            
            conn = get_db_connection()
            cursor = conn.cursor()
            
            try:
                cursor.execute("BEGIN")
                cursor.execute("""
                    INSERT INTO user_account (
                        email, 
                        username,
                        password_hash, 
                        plan,
                        monthly_cost, 
                        created_at, 
                        last_login,
                        next_process_date, 
                        next_process_type
                    ) VALUES (
                        %s, %s, %s, %s, 0.0, %s, %s,
                        NULL, NULL
                    )
                """, (email, username, hashed_password, plan,
                    current_time, current_time))

                cursor.execute("COMMIT")
                return True, "アカウント作成成功"

            except Exception as e:
                cursor.execute("ROLLBACK")
                raise e
            finally:
                cursor.close()
                conn.close()

        except Exception as e:
            print(f"Signup service error: {e}")
            return False, str(e)

    @staticmethod
    def login(email, password):
        """ユーザーログイン処理"""


        query = """
            SELECT password_hash, login_attempts, last_attempt_time, unlock_token 
            FROM user_account 
            WHERE email = %s
        """
        
        result = execute_query(query, (email,))
        if not result or len(result) == 0:
            return False, "ユーザーが見つかりません"
            
        user = result[0]
            
        # ロックアウトチェック
        if user['login_attempts'] >= int(os.getenv('MAX_LOGIN_ATTEMPTS', 5)):
            if user['last_attempt_time']:
                lockout_time = user['last_attempt_time'] + timedelta(minutes=int(os.getenv('LOCKOUT_TIME', 30)))
                if datetime.now() < lockout_time:
                    if not user['unlock_token']:
                        unlock_token = s.dumps(email, salt='unlock-salt')
                        execute_query("""
                            UPDATE user_account
                            SET unlock_token = %s
                            WHERE email = %s
                        """, (unlock_token, email))

                        unlock_link = f"{os.getenv('SERVER_URL')}/unlock_account/{unlock_token}"
                        EmailService.send_unlock_notification(email, unlock_link)

                    # ログを追加
                    print(f"アカウントロック: {email}, 次回試行可能時刻: {lockout_time}")
                    return False, "アカウントがロックされています。解除メールを確認してください。"



        # パスワードチェックを修正
        try:
            if pbkdf2_sha256.verify(password, user['password_hash']):
                execute_query("""
                    UPDATE user_account 
                    SET login_attempts = 0, 
                        last_attempt_time = NULL, 
                        unlock_token = NULL,
                        last_login = %s
                    WHERE email = %s
                """, (datetime.now(), email))
                return True, "ログイン成功"
            else:
                new_attempts = user['login_attempts'] + 1
                execute_query("""
                    UPDATE user_account 
                    SET login_attempts = %s, 
                        last_attempt_time = %s 
                    WHERE email = %s
                """, (new_attempts, datetime.now(), email))
                
                return False, f"パスワードが間違っています {new_attempts}/{Config.MAX_LOGIN_ATTEMPTS}"
        except Exception as e:
            print(f"Password check error: {e}")
            return False, "認証エラーが発生しました"



    @staticmethod
    def reset_password(email, new_password):
        """パスワードリセット"""
        hashed_password = pbkdf2_sha256.hash(new_password)
        return execute_query("""
            UPDATE user_account 
            SET password_hash = %s 
            WHERE email = %s
        """, (hashed_password, email))

    # その他のメソッドは変更なし
    
    @staticmethod
    def unlock_account(email):
        """アカウントロック解除"""
        return execute_query("""
            UPDATE user_account 
            SET login_attempts = 0, 
                last_attempt_time = NULL, 
                unlock_token = NULL 
            WHERE email = %s
        """, (email,))
    
    
    @staticmethod
    def handle_google_login(google_data: dict) -> tuple[bool, str]:
        """
        Googleログインを処理し、必要に応じてユーザーを作成
        """
        try:
            email = google_data.get('email')
            name = google_data.get('name', '')
            google_id = google_data.get('sub')  # Googleの一意のID
            
            conn = get_db_connection()
            cursor = conn.cursor()
            
            try:
                cursor.execute("BEGIN")
                
                # 既存ユーザーの確認
                cursor.execute("""
                    SELECT * FROM user_account 
                    WHERE email = %s
                """, (email,))
                user = cursor.fetchone()
                
                if user:
                    # 既存ユーザーの更新
                    cursor.execute("""
                        UPDATE user_account SET
                            last_login = NOW(),
                            login_attempts = 0
                        WHERE email = %s
                    """, (email,))
                else:
                    # 新規ユーザーの作成
                    cursor.execute("""
                        INSERT INTO user_account (
                            email,
                            username,
                            plan,
                            created_at,
                            last_login,
                            next_process_date,
                            next_process_type,
                            monthly_cost,
                            chat_history_max_length,
                            input_text_length,
                            sortorder,
                            selectedmodel
                        ) VALUES (
                            %s, %s, 'Free', NOW(), NOW(),
                            NULL,  
                            NULL,  
                            0,
                            1000,
                            200,
                            'created_at ASC',
                            'gpt-3.5-turbo'
                        )
                    """, (email, name))
                
                cursor.execute("COMMIT")
                return True, "ログイン成功"
                
            except Exception as e:
                cursor.execute("ROLLBACK")
                raise
                
            finally:
                cursor.close()
                conn.close()
                
        except Exception as e:
            print(f"Googleログイン処理エラー: {e}")
            return False, str(e)
  