# app/routes/auth.py
from flask import Blueprint, request, jsonify, render_template
from ..services.websocket import WebSocketService
from ..services.auth import AuthService
from ..services.email import EmailService
from itsdangerous import URLSafeTimedSerializer, SignatureExpired
from ..config import Config
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
        
        if 'access_token' not in data:
            return jsonify({
                "success": False,
                "message": "認証情報が無効です"
            }), 400
            
        email = data.get('email')
        name = data.get('name', '')
        
        # サービスレイヤーに処理を委譲
        success, message = AuthService.handle_google_login({
            'email': email,
            'name': name
        })
        
        if success:
            return jsonify({
                "success": True,
                "message": message,
                "email": email
            }), 200
            
        return jsonify({
            "success": False,
            "message": message
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
        data = request.json
        if not data or not data.get('email'):
            return jsonify({"message": "メールアドレスは必須です"}), 400
            
        exists = AuthService.check_email_exists(data.get('email'))
        
        if exists:
            return jsonify({"message": "このメールアドレスは既に登録されています"}), 400
            
        return jsonify({"message": "利用可能なメールアドレスです"}), 200
        
    except Exception as e:
        print(f"Email check error: {e}")
        return jsonify({"message": "サーバーエラーが発生しました"}), 500


@bp.route('/signup', methods=['POST'])
def signup():
    try:
        data = request.json
        print(f'Received signup data: {data}')
        
        # リクエストのバリデーション
        if not _validate_signup_data(data):
            return jsonify({"error": "Required fields are missing"}), 400
            
        # データの抽出
        signup_data = {
            'email': data.get('email'),
            'username': data.get('username'),
            'password': data.get('password'),
            'plan': data.get('plan', 'Free'),
            'selected_model': data.get('selected_model', 'gpt-3.5-turbo')
        }
        
        # サービスレイヤーに処理を委譲
        success, message = AuthService.signup(**signup_data)
        
        if success:
            return jsonify({"message": message}), 200
        return jsonify({"error": message}), 500
        
    except Exception as e:
        print(f"Signup error: {e}")
        return jsonify({"error": "サーバーエラーが発生しました"}), 500

def _validate_signup_data(data):
    """サインアップデータの基本的なバリデーション"""
    required_fields = ['email', 'username', 'password']
    return all(data.get(field) for field in required_fields)




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
        return render_template('error.html', error_message="URLの有効期限が切れています。再度リクエストしてください。"), 400


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



@bp.route('/send_verification_email', methods=['POST'])
def send_verification_email():
    try:
        data = request.json
        email = data.get('email')
        username = data.get('username')
        password = data.get('password')

        if not all([email, username, password]):
            return jsonify({"message": "必要な情報が不足しています"}), 400

        # 全ての情報をトークンに含める
        token_data = {
            'email': email,
            'username': username,
            'password': password
        }
        verification_token = s.dumps(token_data, salt='email-verification-salt')
        verification_link = f"{os.getenv('SERVER_URL')}/verify_email/{verification_token}"
        
        if EmailService.send_verification_email(email, username, verification_link):
            return jsonify({"message": "認証メールを送信しました"}), 200

        return jsonify({"message": "メール送信に失敗しました"}), 500
    
    except Exception as e:
        print(f"Error sending verification email: {e}")
        return jsonify({"message": "サーバーエラーが発生しました"}), 500


@bp.route('/verify_email/<token>', methods=['GET'])
def verify_email(token):
    try:
        # トークンから情報を取得
        token_data = s.loads(token, salt='email-verification-salt', max_age=86400)
        
        # アカウント登録処理
        signup_data = {
            'email': token_data['email'],
            'username': token_data['username'],
            'password': token_data['password'],
            'plan': 'Free',
            'selected_model': 'gpt-3.5-turbo'
        }
        
        success, message = AuthService.signup(**signup_data)
        
        if success:
            # Flaskのcurrent_appを使用
            from flask import current_app
            socketio = current_app.extensions.get('socketio')
            if socketio:
                socketio.emit('registration_complete', {
                    'email': token_data['email'],
                    'status': 'success'
                })
                print(f"WebSocket notification sent for: {token_data['email']}")
            else:
                print("SocketIO not initialized")
            
            return render_template('success.html')
        else:
            return render_template('error.html', error_message=message)

    except SignatureExpired:
        return render_template('error.html', 
            error_message="認証リンクの有効期限が切れています")
    except Exception as e:
        print(f"Registration error: {e}")
        return render_template('error.html', 
            error_message="登録処理中にエラーが発生しました")