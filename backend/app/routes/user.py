# app/routes/user.py
from flask import Blueprint, request, jsonify
from ..services.user import UserService
from ..services.tokenizer import TokenizerService
from ..database import execute_query
from dotenv import load_dotenv
import os


bp = Blueprint('user', __name__)


@bp.route('/api/get-secret-config', methods=['GET'])
def get_config():
    config = {
        "GOOGLE_CLIENT_ID": os.getenv("GOOGLE_CLIENT_ID"),
        "MY_TOKEN": os.getenv("MY_TOKEN"),
        "LOGIN_VALUE": os.getenv("LOGIN_VALUE"),
        "LOGIN_UNIT": os.getenv("LOGIN_UNIT"),
    }
    return jsonify(config)




@bp.route('/update/<field>', methods=['POST'])
def update_field(field):
    data = request.json
    email = data.get('email')

    if not email:
        return jsonify({"message": "Email is required"}), 400

    field_mapping = {
        "input_length": ("input_text_length", "input_text_length"),
        "history_length": ("chat_history_max_length", "chat_history_max_length"),
        "sort_order": ("sortorder", "sortOrder"),
        "darkmode": ("isdarkmode", "isDarkMode"),
        "user_name": ("user_name", "user_name"),
        "model": ("selectedmodel", "selectedModel"),
        "monthlycost": ("monthly_cost", "monthly_cost")
    }

    if field not in field_mapping:
        return jsonify({"message": f"Unknown field: {field}"}), 400

    db_field, json_field = field_mapping[field]
    value = data.get(json_field)
    increment = field == "monthlycost"

    if UserService.update_user_data(db_field, value, email, increment):
        return jsonify({"message": f"{field} updated successfully"}), 200
    return jsonify({"message": f"Failed to update {field}"}), 500

# ユーザー情報をロード
@bp.route('/get/config_and_cost', methods=['GET'])
def get_config_and_cost():
    try:
        email = request.args.get('email')
        if not email:
            return jsonify({"message": "メールアドレスが必要です"}), 400

        # PostgreSQLのデータ型を考慮したクエリ
        query = """
            SELECT 
                COALESCE(plan, 'Free') as plan,
                COALESCE(monthly_cost, 0.0) as monthly_cost,
                COALESCE(chat_history_max_length, 1000) as chat_history_max_length,
                COALESCE(input_text_length, 200) as input_text_length,
                COALESCE(user_name, '') as user_name,
                COALESCE(isdarkmode, false) as isdarkmode,
                COALESCE(selectedmodel, 'gpt-4o-mini') as selectedmodel,
                COALESCE(sortorder, 'created_at ASC') as sortorder
            FROM user_account
            WHERE email = %s
        """
        result = execute_query(query, (email,))
        
        if not result:
            return jsonify({
                "plan": "Free",
                "monthly_cost": 0.0,
                "chat_history_max_length": 1000,
                "input_text_length": 200,
                "user_name": "",
                "isDarkMode": False,
                "selectedModel": "gpt-4o-mini",
                "sortOrder": "created_at ASC"
            }), 200

        user_data = result[0]
        return jsonify({
            "plan": user_data["plan"],
            "monthly_cost": float(user_data["monthly_cost"]),
            "chat_history_max_length": int(user_data["chat_history_max_length"]),
            "input_text_length": int(user_data["input_text_length"]),
            "user_name": user_data["user_name"],
            "isDarkMode": bool(user_data["isdarkmode"]),  # PostgreSQLのboolean型を正しく変換
            "selectedModel": user_data["selectedmodel"],
            "sortOrder": user_data["sortorder"]
        }), 200

    except Exception as e:
        print(f"Error getting config and cost: {e}")
        return jsonify({"message": "サーバーエラーが発生しました"}), 500
    
@bp.route('/tokenize', methods=['POST'])
def tokenize():
    data = request.json
    text = data.get('text', '')
    
    tokenizer = TokenizerService()
    token_count = tokenizer.count_tokens(text)
    
    return jsonify({'tokens': token_count})