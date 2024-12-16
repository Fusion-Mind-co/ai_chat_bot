# run.py
import threading
import schedule
import time
from datetime import datetime
from app import create_app
from app.services.subscription import SubscriptionService
from waitress import serve
from app.config import Config
from flask_socketio import SocketIO

app = create_app()
socketio = SocketIO(app, cors_allowed_origins="*")

# グローバル変数
scheduler_running = False

class SchedulerThread:
    def __init__(self, app):
        self.app = app
        self.running = False

    def run_schedule(self):
        if self.running:
            return
        self.running = True
        
        print(f"\n=== スケジューラー起動: {datetime.now()} ===")
        
        def check_task():
            with self.app.app_context():
                try:
                    print(f"\n=== 定期チェック実行: {datetime.now()} ===")
                    SubscriptionService.check_and_process_subscriptions()
                    print("=== 定期チェック完了 ===\n")
                except Exception as e:
                    print(f"スケジュールタスク実行エラー: {e}")
        
        schedule.every(Config.get_scheduler_interval()).minutes.do(check_task)
        print(f"スケジューラー: {Config.get_scheduler_interval()}分間隔で起動")
        
        while True:
            try:
                schedule.run_pending()
                time.sleep(10)
                print(".", end="", flush=True)
            except Exception as e:
                print(f"スケジューラーエラー: {e}")

def start_scheduler():
    scheduler = SchedulerThread(app)
    
    if Config.ENVIRONMENT == 'development':
        import os
        if os.environ.get('WERKZEUG_RUN_MAIN') == 'true':
            schedule_thread = threading.Thread(target=scheduler.run_schedule)
            schedule_thread.daemon = True
            schedule_thread.start()
            print("スケジューラースレッド起動完了（開発環境）")
    else:
        schedule_thread = threading.Thread(target=scheduler.run_schedule)
        schedule_thread.daemon = True
        schedule_thread.start()
        print("スケジューラースレッド起動完了（本番環境）")

if __name__ == "__main__":
    print(f"アプリケーション起動: {datetime.now()}")
    print(f"環境: {Config.ENVIRONMENT}")
    
    start_scheduler()
    
    if Config.ENVIRONMENT == 'development':
        socketio.run(app, host='0.0.0.0', port=5000, debug=True)
    else:
        socketio.run(app, host='0.0.0.0', port=5000)