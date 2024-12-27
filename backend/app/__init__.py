# app/__init__.py
from flask import Flask
from flask_cors import CORS
from .config import Config
import os

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)
    
    # CORS設定
    CORS(app, resources={r"/*": {"origins": "*"}})
    
    # SocketIO初期化
    from flask_socketio import SocketIO
    socketio = SocketIO(app, cors_allowed_origins="*")
    
    # 各種初期化
    from .services import stripe
    stripe.init_app(app)
    
    # Blueprintの登録
    from .routes import auth, user, payment
    app.register_blueprint(auth.bp)
    app.register_blueprint(user.bp)
    app.register_blueprint(payment.bp)
    
    return app