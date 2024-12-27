# backend\app\services\existing socket_service.py

class WebSocketService:
    @staticmethod
    def notify_registration_complete(data):
        socketio.emit('registration_complete', data)

    @staticmethod
    def notify_user_update(email):
        socketio.emit('user_status_update', {'email': email})