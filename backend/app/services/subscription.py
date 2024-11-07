# app/services/subscription.py
from datetime import datetime
from ..database import get_db_connection
from .stripe import StripeService
from ..config import Config

class SubscriptionService:
    @staticmethod
    def check_and_process_subscriptions():
        """サブスクリプションの自動チェックと処理"""
        print("\n=== サブスクリプション処理開始 ===")
        
        conn = get_db_connection()
        cursor = conn.cursor()

        try:
            # 1. Freeプランのリセット処理（新規追加）
            cursor.execute("""
                SELECT email, plan
                FROM user_account
                WHERE 
                    next_process_date <= NOW()
                    AND next_process_type = 'free'
            """)
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

            # 2. 解約処理 (既存のコード)
            cursor.execute("""
                SELECT email, plan
                FROM user_account
                WHERE 
                    next_process_date <= NOW()
                    AND next_process_type = 'cancel'
            """)

            # 2. 解約処理
            cursor.execute("""
                SELECT email, plan
                FROM user_account
                WHERE 
                    next_process_date <= NOW()
                    AND next_process_type = 'cancel'
            """)
            cancellation_users = cursor.fetchall()
            print(f"解約対象ユーザー数: {len(cancellation_users)}")
            
            for user in cancellation_users:
                try:
                    # 解約記録作成
                    cursor.execute("""
                        INSERT INTO user_payment (
                            email, plan, amount, processed_date, processed_by, message
                        ) VALUES (
                            %s, %s, 0, NOW(), %s, %s
                        )
                    """, (user['email'], user['plan'], 'auto_subscription', 'プラン解約'))


                    # アカウント更新
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

            # 3. プラン変更処理
            cursor.execute("""
                SELECT 
                    email, plan, next_plan, next_process_date
                FROM user_account
                WHERE 
                    next_process_date <= NOW()
                    AND next_process_type = 'plan_change'
            """)
            plan_change_users = cursor.fetchall()
            print(f"プラン変更対象ユーザー数: {len(plan_change_users)}")
            for user in plan_change_users:
                print(f"\nプラン変更処理: {user['email']} ({user['plan']} → {user['next_plan']})")
                
                # 新プランの金額を取得
                new_plan_details = Config.SUBSCRIPTION_PLANS.get(user['next_plan'])
                if not new_plan_details:
                    print(f"エラー: 無効なプラン {user['next_plan']}")
                    continue
                    
                amount = new_plan_details['price']
                print(f"請求金額: ¥{amount}")
                
                try:
                    # Stripe決済処理
                    success, transaction_id, error_message = StripeService.process_subscription_payment(
                        user['email'],
                        amount
                    )
                    
                    # 支払い記録作成
                    cursor.execute("""
                        INSERT INTO user_payment (
                            email, plan, amount, processed_date, processed_by, transaction_id, message
                        ) VALUES (
                            %s, %s, %s, NOW(), %s, %s, %s
                        ) RETURNING id
                    """, (
                        user['email'],
                        user['next_plan'],
                        amount,
                        'plan_change',
                        transaction_id,
                        f"{user['plan']}から{user['next_plan']}へのプラン変更" if success else error_message
                    ))


                    if success:
                        cursor.execute("""
                            UPDATE user_account 
                            SET 
                                plan = next_plan,
                                next_plan = NULL,
                                next_process_type = 'payment',
                                monthly_cost = 0,
                                next_process_date = NOW() + INTERVAL %s,
                                last_payment_date = NOW()
                            WHERE email = %s
                        """, (Config.get_next_process_interval(), user['email']))
                    else:
                        cursor.execute("""
                            UPDATE user_account 
                            SET 
                                plan = 'Free',
                                next_process_type = 'free',
                                next_process_date = NOW() + INTERVAL %s,
                                next_plan = NULL,
                                monthly_cost = 0
                            WHERE email = %s
                        """, (Config.get_next_process_interval(), user['email']))
                        
                    conn.commit()
                except Exception as e:
                    print(f"プラン変更処理エラー: {e}")
                    conn.rollback()
                    # 4. 定期支払い処理
            cursor.execute("""
                SELECT 
                    email, plan, monthly_cost, next_process_date
                FROM user_account
                WHERE 
                    next_process_date <= NOW()
                    AND next_process_type = 'payment'
            """)
            payment_users = cursor.fetchall()
            print(f"\n定期支払い対象ユーザー数: {len(payment_users)}")
            
            for user in payment_users:
                print(f"\n定期支払い処理: {user['email']} ({user['plan']})")
                
                plan_details = Config.SUBSCRIPTION_PLANS.get(user['plan'])
                if not plan_details:
                    print(f"エラー: 無効なプラン {user['plan']}")
                    continue
                    
                amount = plan_details['price']
                print(f"請求金額: ¥{amount}")
                
                try:
                    # Stripe決済処理
                    success, transaction_id, error_message = StripeService.process_subscription_payment(
                        user['email'],
                        amount
                    )
                    
                    # 支払い記録作成
                    cursor.execute("""
                        INSERT INTO user_payment (
                            email, plan, amount, processed_date, processed_by, transaction_id, message
                        ) VALUES (
                            %s, %s, %s, NOW(), %s, %s, %s
                        ) RETURNING id
                    """, (
                        user['email'],
                        user['plan'],
                        amount,
                        'auto_subscription',
                        transaction_id,
                        '定期支払い' if success else error_message
                    ))

                    if success:
                        cursor.execute("""
                            UPDATE user_account 
                            SET 
                                last_payment_date = NOW(),
                                next_process_date = NOW() + INTERVAL %s,
                                monthly_cost = 0
                            WHERE email = %s
                            RETURNING next_process_date
                        """, (Config.get_next_process_interval(), user['email']))
                        print("支払い成功")
                    else:
                        cursor.execute("""
                            UPDATE user_account 
                            SET 
                                plan = 'Free',
                                next_process_type = 'free',
                                next_process_date = NOW() + INTERVAL %s,
                                next_process_type = NULL,
                                monthly_cost = 0
                            WHERE email = %s
                        """, (Config.get_next_process_interval(), user['email']))
                        print(f"支払い失敗: {error_message}")
                    
                    conn.commit()
                except Exception as e:
                    print(f"支払い処理エラー: {e}")
                    conn.rollback()

            print("\n全処理完了")

        except Exception as e:
            print(f"エラー発生: {e}")
            conn.rollback()
        finally:
            cursor.close()
            conn.close()
            print("=== サブスクリプション処理終了 ===\n")

    @staticmethod
    def notify_payment_failure(email):
        """支払い失敗時のユーザー通知"""
        # TODO: メール通知の実装
        pass