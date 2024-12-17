import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chatbot/globals.dart';



Future<void> updateUserData(String endpoint, Map<String, dynamic> data) async {
  print('updateUserData関数起動　PostgreSQLにデータをアップデート');
  final url = Uri.parse('$serverUrl/update/$endpoint');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      print("$endpoint の更新が完了");
    } else {
      print("更新失敗 $endpoint. Status code: ${response.statusCode}");
    }
  } catch (e) {
    print("Error updating $endpoint: $e");
  }
}


Future<String?> getSortOrderFromPostgreSQL() async {
  try {
    final url = Uri.parse('$serverUrl/get/sort_order?email=$globalEmail');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['sortOrder'] as String?;
    } else {
      print("Failed to get SortOrder from PostgreSQL");
      return null;
    }
  } catch (e) {
    print("Error fetching SortOrder: $e");
    return null;
  }
}


// // MonthlyCostとPlanの取得
Future<Map<String, dynamic>?> fetchCostPlan() async {
  if (globalEmail == null) {
    print('emailが指定されていません');
    return null;
  }

  final url = Uri.parse('$serverUrl/get/cost_plan?email=$globalEmail');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    var responseData = jsonDecode(response.body);
    print('サーバーからのレスポンス: $responseData'); // デバッグ用にレスポンス内容を表示

    if (responseData is Map &&
        responseData.containsKey('monthly_cost') &&
        responseData.containsKey('plan')) {
      var monthlyCost = responseData['monthly_cost'];
      var plan = responseData['plan'];
      print('Monthly Cost: $monthlyCost, Plan: $plan');

      globalMonthlyCost = monthlyCost; // グローバル変数にセット
      globalPlan = plan; // グローバル変数にセット
      return {'monthly_cost': monthlyCost, 'plan': plan};
    } else {
      print('データの形式が正しくありません');
      return null;
    }
  } else {
    print('取得失敗');
    return null;
  }
}

// MonthlyCost取得
// =========================================現在未使用===============================================
Future<double?> fetchMonthlyCost() async {
  if (globalEmail == null) {
    print('emailが指定されていません');
    return null;
  }

  final url = Uri.parse('$serverUrl/get/monthlycost?email=$globalEmail');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    var responseData = jsonDecode(response.body);
    if (responseData is Map && responseData.containsKey('monthly_cost')) {
      var monthlyCost = responseData['monthly_cost'];
      print('Monthly Cost: $monthlyCost');

      // グローバル変数にセット
      var globalMonthlyCost = monthlyCost;
      return monthlyCost;
    } else {
      print('データの形式が正しくありません');
      return null;
    }
  } else {
    print('取得失敗');
    return null;
  }
}
// =========================================現在未使用===============================================

Future<void> updateMonthlyCost(double additionalCost) async {
  final url = Uri.parse('$serverUrl/update/monthlycost');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'email': globalEmail, // グローバル変数のemailを使用
      'monthly_cost': additionalCost, // 加算するコスト
    }),
  );

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    globalMonthlyCost = responseData['new_monthly_cost']; // 最新のコストをグローバル変数に設定
    print('Monthly cost updated: ${globalMonthlyCost}');
  } else {
    print('Failed to update monthly cost');
  }
}
