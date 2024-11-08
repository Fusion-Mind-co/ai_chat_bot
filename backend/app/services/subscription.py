# app/services/subscription.py
from datetime import datetime
from ..database import get_db_connection
from .stripe import StripeService
from ..config import Config

class SubscriptionService:

    # サブスクリプションの自動チェックと処理を行う関数
    @staticmethod
    def check_and_process_subscriptions():
        """サブスクリプションの自動チェックと処理"""
        print("\n=== サブスクリプション処理開始 ===")

        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                try:
                    # 1. Freeプランのリセット処理
                    SubscriptionService.reset_free_plan(cursor, conn)

                    # 2. 解約処理
                    SubscriptionService.process_cancellations(cursor, conn)

                    # 3. プラン変更処理
                    SubscriptionService.process_plan_changes(cursor, conn)

                    # 4. 定期支払い処理
                    SubscriptionService.process_regular_payments(cursor, conn)

                    print("\n全処理完了")

                except Exception as e:
                    print(f"エラー発生: {e}")
                    conn.rollback()
                finally:
                    print("=== サブスクリプション処理終了 ===\n")

    # Freeプランのリセットを行う関数
    @staticmethod
    def reset_free_plan(cursor, conn):
        """Freeプランのリセット処理"""
        cursor.execute("""
            SELECT email, plan
            FROM user_account
            WHERE 
                next_process_date <= NOW()
                AND next_process_type = %s
        """, ('free',))
        free_users = cursor.fetchall()
        print(f"Freeプランリセット対象ユーザー数: {len(free_users)}")

        for user in free_users:
            try:
                cursor.execute("""
                    UPDATE user_account 
                    SET 
                        monthly_cost = 0,
                        next_process_date = NOW() + INTERVAL %s
                    WHERE email = %s
                """, (Config.get_next_process_interval(), user['email']))
                conn.commit()
            except Exception as e:
                print(f"Freeプランリセットエラー: {e}")
                conn.rollback()

    # 解約処理を行う関数
    @staticmethod
    def process_cancellations(cursor, conn):
        """解約処理"""
        cursor.execute("""
            SELECT email, plan
            FROM user_account
            WHERE 
                next_process_date <= NOW()
                AND next_process_type = %s
        """, ('cancel',))
        cancellation_users = cursor.fetchall()
        print(f"解約対象ユーザー数: {len(cancellation_users)}")

        for user in cancellation_users:
            try:
                SubscriptionService.create_payment_record(cursor, user['email'], user['plan'], 0, 'auto_subscription', message='プラン解約')
                cursor.execute("""
                    UPDATE user_account 
                    SET 
                        next_process_type = NULL,
                        next_process_date = NULL,
                        plan = 'Free',
                        monthly_cost = 0,
                        next_plan = NULL
                    WHERE email = %s
                """, (user['email'],))
                conn.commit()
            except Exception as e:
                print(f"解約処理エラー: {e}")
                conn.rollback()

    # プラン変更の処理を行う関数
    @staticmethod
    def process_plan_changes(cursor, conn):
        """プラン変更処理"""
        cursor.execute("""
            SELECT 
                email, plan, next_plan, next_process_date
            FROM user_account
            WHERE 
                next_process_date <= NOW()
                AND next_process_type = %s
        """, ('plan_change',))
        plan_change_users = cursor.fetchall()
        print(f"プラン変更対象ユーザー数: {len(plan_change_users)}")

        for user in plan_change_users:
            print(f"\nプラン変更処理: {user['email']} ({user['plan']} → {user['next_plan']})")

            new_plan_details = Config.SUBSCRIPTION_PLANS.get(user['next_plan'])
            if not new_plan_details:
                print(f"エラー: 無効なプラン {user['next_plan']}")
                continue

            amount = new_plan_details['price']
            print(f"請求金額: ¥{amount}")

            try:
                success, transaction_id, error_message = StripeService.process_subscription_payment(
                    user['email'],
                    amount
                )

                SubscriptionService.create_payment_record(cursor, user['email'], user['next_plan'], amount, 'plan_change', transaction_id, f"{user['plan']}から{user['next_plan']}へのプラン変更" if success else error_message)

                if success:
                    SubscriptionService.update_next_process(cursor, user['email'], 'payment', Config.get_next_process_interval())
                else:
                    SubscriptionService.update_next_process(cursor, user['email'], 'free', Config.get_next_process_interval())

                conn.commit()
            except Exception as e:
                print(f"プラン変更処理エラー: {e}")
                conn.rollback()

    # 定期支払い処理を行う関数
    @staticmethod
    def process_regular_payments(cursor, conn):
        """定期支払い処理"""
        cursor.execute("""
            SELECT 
                email, plan, monthly_cost, next_process_date
            FROM user_account
            WHERE 
                next_process_date <= NOW()
                AND next_process_type = %s
        """, ('payment',))
        payment_users = cursor.fetchall()
        print(f"\n定期支払い対象ユーザー数: {len(payment_users)}")

        for user in payment_users:
            print(f"\n定期支払い処理: {user['email']} ({user['plan']})")

            try:
                # Freeプランの場合は特別処理
                if user['plan'] == 'Free':
                    # コストリセットと次回処理日の更新のみ
                    cursor.execute("""
                        UPDATE user_account 
                        SET 
                            monthly_cost = 0,
                            next_process_date = NOW() + INTERVAL %s,
                            next_process_type = 'payment'
                        WHERE email = %s
                    """, (Config.get_next_process_interval(), user['email']))
                    
                    # 処理記録
                    SubscriptionService.create_payment_record(
                        cursor, 
                        user['email'], 
                        'Free', 
                        0, 
                        'auto_free_reset', 
                        message='Freeプランリセット'
                    )
                    
                    conn.commit()
                    continue  # 次のユーザーへ

                # 有料プランの通常処理
                plan_details = Config.SUBSCRIPTION_PLANS.get(user['plan'])
                if not plan_details:
                    print(f"エラー: 無効なプラン {user['plan']}")
                    continue

                amount = plan_details['price']
                print(f"請求金額: ¥{amount}")

                # 支払い処理
                success, transaction_id, error_message = StripeService.process_subscription_payment(
                    user['email'],
                    amount
                )

                # 支払い記録の作成
                SubscriptionService.create_payment_record(
                    cursor, 
                    user['email'], 
                    user['plan'], 
                    amount, 
                    'auto_subscription', 
                    transaction_id, 
                    '定期支払い' if success else error_message
                )

                # 次回処理日の更新
                if success:
                    SubscriptionService.update_next_process(cursor, user['email'], 'payment', Config.get_next_process_interval())
                else:
                    SubscriptionService.update_next_process(cursor, user['email'], 'free', Config.get_next_process_interval())

                conn.commit()
            except Exception as e:
                print(f"支払い処理エラー: {e}")
                conn.rollback()



    # 支払い記録を作成する共通関数
    @staticmethod
    def create_payment_record(cursor, email, plan, amount, processed_by, transaction_id=None, message=''):
        """支払い記録を作成する共通関数"""
        cursor.execute("""
            INSERT INTO user_payment (
                email, plan, amount, processed_date, processed_by, transaction_id, message
            ) VALUES (
                %s, %s, %s, NOW(), %s, %s, %s
            )
            RETURNING id
        """, (email, plan, amount, processed_by, transaction_id, message))
        payment_record = cursor.fetchone()
        print(f"支払い記録作成: ID {payment_record['id']}")
        return payment_record['id']

    # 次回処理日を更新する共通関数
    @staticmethod
    def update_next_process(cursor, email, next_process_type, interval):
        """次回処理日を更新する共通関数"""
        cursor.execute("""
            UPDATE user_account 
            SET 
                next_process_type = %s,
                next_process_date = NOW() + INTERVAL %s
            WHERE email = %s
        """, (next_process_type, interval, email))
        print(f"次回処理日を更新: email={email}, next_process_type={next_process_type}")
