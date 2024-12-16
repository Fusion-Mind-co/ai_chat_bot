# app/services/websocket.py として新規作成
from flask import current_app

class WebSocketService:
    @staticmethod
    def notify_user_update(email):
        try:
            socketio = current_app.extensions['socketio']
            socketio.emit('user_status_update', {'email': email})
            print(f"WebSocket通知送信成功: {email}")
        except Exception as e:
            print(f"WebSocket通知エラー: {e}")
