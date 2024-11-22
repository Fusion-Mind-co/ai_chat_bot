# app/routes/user.py
from flask import Blueprint, request, jsonify
from ..services.user import UserService
from ..services.tokenizer import TokenizerService
from ..database import execute_query

bp = Blueprint('user', __name__)

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


@bp.route('/get/config_and_cost', methods=['GET'])
def get_config_and_cost():
    try:
        email = request.args.get('email')
        if not email:
            return jsonify({"message": "メールアドレスが必要です"}), 400

        query = """
            SELECT plan, monthly_cost, chat_history_max_length, input_text_length
            FROM user_account
            WHERE email = %s
        """
        result = execute_query(query, (email,))
        print(f"Config query result for {email}: {result}")  # デバッグログ追加
        
        if not result:
            # ユーザーが存在しない場合はデフォルト値を返す
            default_config = {
                "plan": "Free",
                "monthly_cost": 0,
                "chat_history_max_length": 1000,
                "input_text_length": 200
            }
            return jsonify(default_config), 200

        user_data = result[0]
        return jsonify(user_data), 200

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