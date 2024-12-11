# app/routes/payment.py
from flask import Blueprint, request, jsonify
from ..services.stripe import StripeService
from ..services.subscription import SubscriptionService
from ..database import get_db_connection
from ..config import Config
from datetime import datetime, timedelta

bp = Blueprint('payment', __name__)

# 解約手続き
@bp.route('/reserve-cancellation', methods=['POST'])
def reserve_cancellation():
    data = request.json
    email = data.get('email')
    
    if not email:
        return jsonify({"error": "Email is required"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # 解約予約を設定（次回処理日まではサービスを継続）
        cursor.execute("""
            UPDATE user_account 
            SET 
                next_process_type = 'cancel',
                next_process_date = CASE 
                    WHEN next_process_date IS NULL THEN NOW() + INTERVAL '1 minute'
                    ELSE next_process_date
                END
            WHERE email = %s
            RETURNING next_process_date
        """, (email,))
        
        result = cursor.fetchone()
        conn.commit()
        
        return jsonify({
            "message": "Cancellation reserved",
            "next_process_date": result['next_process_date'].isoformat() if result else None
        }), 200
    except Exception as e:
        conn.rollback()
        print(f"解約予約エラー: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()


# payment.py の create_payment_intent
@bp.route('/create-payment-intent', methods=['POST'])
def create_payment_intent():
    print("支払いインテントの作成エンドポイントが呼び出されました。")
    try:
        data = request.json
        amount = data.get('amount')
        email = data.get('email')
        plan = data.get('plan')
        process_type = data.get('process_type', 'payment')

        if not amount or not email or not plan:
            return jsonify({"error": "amount, email and plan are required"}), 400

        print(f"支払いインテントの作成: 金額={amount}, プラン={plan}, 処理タイプ={process_type}")

        try:
            # Stripe PaymentIntent作成
            result = StripeService.create_payment_intent(amount, email)
            payment_intent_id = result.get('payment_intent_id')
            
            # データベース更新
            conn = get_db_connection()
            cursor = conn.cursor()
            try:
                # user_accountテーブルの更新
                cursor.execute("""
                    UPDATE user_account 
                    SET 
                        next_process_date = NOW() + INTERVAL '1 minute',
                        next_process_type = %s
                    WHERE email = %s
                """, (process_type, email))

                # 支払い記録の作成
                StripeService.record_payment(
                    email=email,
                    plan=plan,
                    amount=amount,
                    next_process_date=datetime.now() + timedelta(minutes=1),
                    transaction_id=payment_intent_id,
                    message='有料プラン加入支払い'
                )
                
                conn.commit()
            except Exception as e:
                conn.rollback()
                raise e
            finally:
                cursor.close()
                conn.close()
            
            return jsonify({
                'client_secret': result['client_secret']
            }), 200
            
        except Exception as e:
            print(f"Stripe処理エラー: {e}")
            raise
            
    except Exception as e:
        print(f"エラー: 支払いインテントの作成に失敗: {str(e)}")
        return jsonify({"error": str(e)}), 400

@bp.route('/create-subscription', methods=['POST'])
def create_subscription():
    data = request.json
    email = data.get('email')
    
    try:
        customer = StripeService.create_customer(email)
        subscription = StripeService.create_subscription(
            customer.id,
            'your_price_id'  # Stripeダッシュボードの価格ID
        )
        return jsonify({
            'subscription_id': subscription.id,
            'client_secret': subscription.latest_invoice.payment_intent.client_secret
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400


@bp.route('/update/plan', methods=['POST'])
def update_plan():
    try:
        data = request.json
        email = data.get('email')
        plan = data.get('plan')
        process_type = data.get('process_type', 'payment')
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        try:
            next_interval = Config.get_next_process_interval()
            cursor.execute("""
                UPDATE user_account 
                SET 
                    plan = %s,
                    next_process_type = %s,
                    next_process_date = NOW() + INTERVAL %s,
                    monthly_cost = 0,
                    selectedmodel = CASE 
                        WHEN %s = 'Standard' THEN 'gpt-4o'
                        ELSE 'gpt-3.5-turbo'
                    END
                WHERE email = %s
                RETURNING next_process_date, plan, selectedmodel
            """, (
                plan,
                process_type,
                next_interval,
                plan,
                email
            ))
            
            result = cursor.fetchone()
            if not result:
                raise Exception("ユーザーが見つかりません")
                
            conn.commit()
            
            print(f"プラン更新成功: plan={result['plan']}, model={result['selectedmodel']}")
            
            return jsonify({
                "message": "Plan updated successfully",
                "plan": result['plan'],
                "next_process_date": result['next_process_date'].isoformat() if result['next_process_date'] else None,
                "selectedmodel": result['selectedmodel']
            }), 200
            
        except Exception as e:
            conn.rollback()
            print(f"データベース更新エラー: {e}")
            raise
            
        finally:
            cursor.close()
            conn.close()
            
    except Exception as e:
        print(f"プラン更新エラー: {e}")
        return jsonify({"error": str(e)}), 500
    


@bp.route('/get/user_status', methods=['GET'])
def get_user_status():
    email = request.args.get('email')
    
    if not email:
        return jsonify({"error": "Email is required"}), 400
        
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            SELECT 
                plan,
                next_process_date,
                next_process_type,
                monthly_cost,
                selectedmodel
            FROM user_account 
            WHERE email = %s
        """, (email,))
        
        user_data = cursor.fetchone()
        
        if user_data:
            return jsonify({
                "plan": user_data['plan'],
                "next_process_date": user_data['next_process_date'].isoformat() if user_data['next_process_date'] else None,
                "next_process_type": user_data['next_process_type'],
                "monthly_cost": float(user_data['monthly_cost']) if user_data['monthly_cost'] is not None else 0,
                "selectedmodel": user_data['selectedmodel']
            }), 200
        else:
            return jsonify({"error": "User not found"}), 404
            
    except Exception as e:
        print(f"ユーザー状態の取得エラー: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()



# 支払い履歴閲覧
# payment.py に追加
@bp.route('/get/payment_history', methods=['GET'])
def get_payment_history():
    email = request.args.get('email')
    
    if not email:
        return jsonify({"error": "Email is required"}), 400
        
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            SELECT processed_date, message, amount
            FROM user_payment
            WHERE email = %s
            ORDER BY processed_date DESC
        """, (email,))
        
        history = []
        for record in cursor.fetchall():
            history.append({
                'processed_date': record['processed_date'].isoformat(),
                'message': record['message'],
                'amount': record['amount']
            })
            
        return jsonify({"history": history}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()