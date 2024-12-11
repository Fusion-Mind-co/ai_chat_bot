# app/routes/auth.py
from flask import Blueprint, request, jsonify, render_template
from ..services.auth import AuthService
from ..services.email import EmailService
from itsdangerous import URLSafeTimedSerializer, SignatureExpired
from ..config import Config
from ..database import execute_query  
from ..database import get_db_connection  
from datetime import datetime, timedelta
from dotenv import load_dotenv
import os

bp = Blueprint('auth', __name__)

# シリアライザーの初期化
s = URLSafeTimedSerializer(Config.SECRET_KEY)

# google_login認証
@bp.route('/google-login', methods=['POST'])
def google_login():
    try:
        data = request.json
        print(f"Received data: {data}")
        
        if 'access_token' in data:
            email = data.get('email')
            name = data.get('name', '')
            
            conn = get_db_connection()
            cursor = conn.cursor()
            
            try:
                cursor.execute("BEGIN")
                
                cursor.execute("""
                    SELECT * FROM user_account WHERE email = %s
                """, (email,))
                
                user = cursor.fetchone()
                print(f"Found user: {user}")
                
                if not user:
                    cursor.execute("""
                        INSERT INTO user_account (
                            email, username, plan, created_at, last_login,
                            next_process_date, next_process_type, monthly_cost,
                            chat_history_max_length, input_text_length, sortorder,
                            selectedmodel
                        ) VALUES (
                            %s, %s, 'Free', NOW(), NOW(),
                            NULL, NULL, 
                            0, 1000, 200, 'created_at ASC',
                            'gpt-3.5-turbo'
                        )
                    """, (email, name))
                    
                    print(f"Created new user with email: {email}")
                    message = "アカウントを新規作成しました"
                    
                else:
                    # 既存ユーザーの更新
                    cursor.execute("""
                        UPDATE user_account SET
                            last_login = NOW(),
                            login_attempts = 0
                        WHERE email = %s
                    """, (email,))
                    message = "ログインしました"
                
                cursor.execute("COMMIT")
                return jsonify({
                    "success": True,
                    "message": message,
                    "email": email
                }), 200
                
            except Exception as e:
                cursor.execute("ROLLBACK")
                print(f"Database error: {e}")
                return jsonify({
                    "success": False,
                    "message": "データベースエラーが発生しました"
                }), 500
            finally:
                cursor.close()
                conn.close()
        
        return jsonify({
            "success": False,
            "message": "認証情報が無効です"
        }), 400
        
    except Exception as e:
        print(f"Login error: {e}")
        return jsonify({
            "success": False,
            "message": "サーバーエラーが発生しました"
        }), 500


@bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.json
        if not data:
            return jsonify({"message": "Invalid JSON"}), 400
            
        email = data.get('email')
        password = data.get('password')

        if not email or not password:
            return jsonify({"message": "emailとパスワードは必須です"}), 400

        success, message = AuthService.login(email, password)
        if success:
            return jsonify({"message": message}), 200
        return jsonify({"message": message}), 401
    except Exception as e:
        print(f"Login error: {e}")
        return jsonify({"message": "サーバーエラーが発生しました"}), 500
    
@bp.route('/check_email', methods=['POST'])
def check_email():
    try:
        print("Received check_email request")  # デバッグ用
        data = request.json
        print(f"Request data: {data}")  # デバッグ用
        
        if not data:
            print("No JSON data received")  # デバッグ用
            return jsonify({"message": "Invalid JSON"}), 400
            
        email = data.get('email')
        print(f"Email to check: {email}")  # デバッグ用
        
        if not email:
            print("No email provided")  # デバッグ用
            return jsonify({"message": "メールアドレスは必須です"}), 400

        # メールアドレスの重複チェック
        query = "SELECT COUNT(*) as count FROM user_account WHERE email = %s"
        result = execute_query(query, (email,))
        print(f"Query result: {result}")  # デバッグ用
        
        if result and result[0]['count'] > 0:
            return jsonify({"message": "このメールアドレスは既に登録されています"}), 400
            
        return jsonify({"message": "利用可能なメールアドレスです"}), 200
        
    except Exception as e:
        print(f"Email check error: {e}")  # デバッグ用
        return jsonify({"message": "サーバーエラーが発生しました"}), 500

# auth.py の signup エンドポイントを修正

@bp.route('/signup', methods=['POST'])
def signup():
    data = request.json
    email = data.get('email')
    username = data.get('username')
    password = data.get('password')
    plan = data.get('plan', 'Free')  
    selected_model = data.get('selected_model', 'gpt-3.5-turbo')  
    
    if not all([email, password]):
        return jsonify({"error": "Required fields are missing"}), 400
        
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # パスワードのハッシュ化
        password_hash = generate_password_hash(password)
        
        # ユーザーアカウントの作成
        cursor.execute("""
            INSERT INTO user_account (
                email, 
                username, 
                password_hash, 
                plan,
                selectedmodel,
                created_at
            ) VALUES (
                %s, %s, %s, %s, %s, NOW()
            )
        """, (email, username, password_hash, plan, selected_model))
        
        conn.commit()
        return jsonify({"message": "User registered successfully"}), 200
        
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

def _validate_signup_data(data):
    return all([
        data.get('email'),
        data.get('username'),
        data.get('password')
    ])



@bp.route('/reset_password_request', methods=['POST'])
def reset_password_request():
    print('def reset_password_request')
    data = request.json
    email = data.get('email')
    
    if not email:
        return jsonify({"message": "メールアドレスが必要です"}), 400

    token = s.dumps(email, salt='password-reset-salt')
    reset_link = f"{os.getenv('SERVER_URL')}/reset_password/{token}"
    
    if EmailService.send_reset_password(email, reset_link):
        return jsonify({"message": "パスワードリセットのリンクが送信されました"}), 200
    return jsonify({"message": "メール送信に失敗しました"}), 500


@bp.route('/reset_password/<token>', methods=['GET', 'POST'])
def reset_password(token):
    try:
        email = s.loads(token, salt='password-reset-salt', max_age=3600)
    except SignatureExpired:
        return jsonify({"message": "リセットリンクの有効期限が切れています"}), 400

    if request.method == 'POST':
        new_password = request.form.get('new_password')
        if AuthService.reset_password(email, new_password):
            return render_template('success.html')
        return render_template('error.html', error_message="パスワードの更新に失敗しました")

    return render_template('reset_password.html')

@bp.route('/unlock_account/<token>', methods=['GET'])
def unlock_account(token):
    try:
        email = s.loads(token, salt='unlock-salt', max_age=3600)
    except SignatureExpired:
        return render_template('error.html', error_message="解除リンクの有効期限が切れています"), 400

    if AuthService.unlock_account(email):
        return render_template('unlock_account.html')  # HTMLテンプレートを返却
    return render_template('error.html', error_message="アカウントの解除に失敗しました"), 500


