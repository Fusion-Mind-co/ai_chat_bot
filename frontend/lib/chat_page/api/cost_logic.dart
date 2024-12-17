// cost_logic.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:chatbot/database/postgreSQL_logic.dart';
import 'package:chatbot/globals.dart'; // グローバル変数をインポート
import 'package:chatbot/main.dart'; // DatabaseServiceをインポート



// モデルごとのコストをマップで管理
Map<String, Map<String, double>> modelCosts = {
  'gpt-4o-mini': {
    'in': gpt_4o_mini_in_cost,
    'out': gpt_4o_mini_out_cost,
  },
  'gpt-3.5-turbo': {
    'in': gpt_3_5_turbo_in_cost,
    'out': gpt_3_5_turbo_out_cost,
  },
  'gpt-4o': {
    'in': gpt_4o_in_cost,
    'out': gpt_4o_out_cost,
  },
};

// コストを計算する関数
Future<void> CostManagement(
  int inputTokens,
  int outputTokens,
  String model,
  int user_text_length,
  int gpt_text_length
) async {
  print('CostManagement 関数');
  if (!modelCosts.containsKey(model)) {
    throw Exception('未知のモデルです: $model');
  }

  // トークン数とモデルからコストを割り当てる
  double inCost = inputTokens * (modelCosts[model]?['in'] ?? 0.0);
  double outCost = outputTokens * (modelCosts[model]?['out'] ?? 0.0);

  // 今回のトータルコスト
  double nowTotalCost = inCost + outCost;

  // PostgreSQLにコストを更新
  await updateUserData('monthlycost', {
    'email': globalEmail, // グローバル変数のemailを使用
    'monthly_cost': nowTotalCost, // 加算するコスト
  });

  print('今回のコスト : $nowTotalCost');
}
