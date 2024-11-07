// payment_page.dart
import 'package:chatbot/chat_page/api/api_config.dart';
import 'package:chatbot/globals.dart';
import 'package:flutter/material.dart' hide Card; // Materialの'Card'を隠す
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:flutter/material.dart' as material show Card;
import 'package:intl/intl.dart'; // Materialの'Card'を別名でインポート

class PaymentPage extends StatefulWidget {
  @override
  PaymentPageState createState() => PaymentPageState();
}

// payment_page.dart
class PaymentPageState extends State<PaymentPage> {
// ＝＝＝＝＝＝20241105＝＝＝＝＝＝＝＝＝＝＝＝＝
  DateTime? nextProcessDate;
  String? nextProcessType;
  String? nextPlan;

  @override
  void initState() {
    super.initState();
    _fetchUserStatus();
  }

// ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝

  String? selectedPlan;

  final Map<String, Map<String, dynamic>> plans = {
    'Light': {
      'price': 980,
      'points': Light_max_monthly_cost.toInt(),
      'description': 'お試し利用プラン',
    },
    'Standard': {
      'price': 1980,
      'points': Standard_max_monthly_cost.toInt(),
      'description': '標準利用プラン',
    },
    'Pro': {
      'price': 2980,
      'points': Pro_max_monthly_cost.toInt(),
      'description': '高機能利用プラン',
    },
    'Expert': {
      'price': 3980,
      'points': Expert_max_monthly_cost.toInt(),
      'description': 'プロフェッショナルプラン',
    },
  };

  Future<void> _handlePayment(String plan) async {
    print('\n=== 支払い処理開始 ===');
    print('選択プラン: $plan');

    try {
      // 1. ユーザーの現在の状態を確認
      final userResponse = await http.get(
        Uri.parse(
            '${dotenv.env['NGROK_URL']}/get/user_status?email=$globalEmail'),
      );

      if (userResponse.statusCode != 200) {
        throw Exception('ユーザー情報の取得に失敗しました');
      }

      final userData = jsonDecode(userResponse.body);
      final currentPlan = userData['plan'];
      final paymentStatus = userData['payment_status'];

      if (!paymentStatus || currentPlan == null) {
        // 2a. 初期決済の場合
        await _handleInitialPayment(plan);
      } else {
        // 2b. プラン変更の場合
        await _handlePlanChange(plan);
      }
    } catch (e) {
      print('エラー発生:');
      print('  タイプ: ${e.runtimeType}');
      print('  メッセージ: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  // 初期決済処理
  Future<void> _handleInitialPayment(String plan) async {
    final planDetails = plans[plan];

    // 1. PaymentIntent作成
    final response = await http.post(
      Uri.parse('${dotenv.env['NGROK_URL']}/create-payment-intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': planDetails!['price'],
        'email': globalEmail,
        'plan': plan,
        'process_type': 'payment'
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('支払いの準備に失敗しました');
    }

    // 2. 決済実行
    final paymentIntentData = jsonDecode(response.body);
    await _processPayment(paymentIntentData);

    // 3. データベース更新
    await _updateUserPlan(plan,
        processType: 'payment' // 'paymentInterval' から 'processType' に変更
        );
    await _updatePaymentStatus(true);
  }

  // _processPaymentメソッドを追加
  Future<void> _processPayment(Map<String, dynamic> paymentIntentData) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          merchantDisplayName: 'ChatGPT Bot',
          style: ThemeMode.system,
        ),
      );

      print('決済シート表示中...');
      await Stripe.instance.presentPaymentSheet();
      print('決済完了');
    } catch (e) {
      print('決済処理エラー: $e');
      throw Exception('決済処理に失敗しました: $e');
    }
  }

  // プラン変更処理
  // プラン変更処理を修正
  Future<void> _handlePlanChange(String newPlan) async {
    // 確認ダイアログを表示
    final currentAmount = planPrices[globalPlan] ?? 0;
    final newAmount = planPrices[newPlan] ?? 0;

    bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('プラン変更の確認'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('以下の内容でプラン変更を予約します：'),
                  SizedBox(height: 8),
                  Text('現在のプラン：$globalPlan (¥$currentAmount/月)'),
                  Text('変更後のプラン：$newPlan (¥$newAmount/月)'),
                  SizedBox(height: 8),
                  Text('※ 次回支払い時にプランが変更されます。'),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('キャンセル'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                  child: Text('変更する'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirm) return;

    try {
      // 1. プラン変更予約
      final response = await http.post(
        Uri.parse('${dotenv.env['NGROK_URL']}/reserve-plan-change'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': globalEmail,
          'new_plan': newPlan,
          'process_type': 'plan_change'
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('プラン変更の予約に失敗しました');
      }

      // 2. 状態を更新 (ここを追加)
      await _fetchUserStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('次回決済時にプランが変更されます')),
      );
    } catch (e) {
      print('エラー発生:');
      print('  タイプ: ${e.runtimeType}');
      print('  メッセージ: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  // ＝＝＝＝＝＝＝＝＝＝＝＝＝＝20241105＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
// 解約ロジック

// payment_page.dart に以下のメソッドを追加
  Future<void> _handleCancellation() async {
    // 確認ダイアログを表示
    bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('解約の確認'),
              content: Text('本当に解約しますか？\n解約は次回の支払日に反映されます。'),
              actions: [
                TextButton(
                  child: Text('キャンセル'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: Text('解約する'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirm) return;

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['NGROK_URL']}/reserve-cancellation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': globalEmail,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('次回支払日に解約が反映されます')),
        );
        // 状態を更新
        _fetchUserStatus();
      } else {
        throw Exception('解約予約に失敗しました');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  // ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝

  Future<void> _updateUserPlan(String plan, {String? processType}) async {
    final response = await http.post(
      Uri.parse('${dotenv.env['NGROK_URL']}/update/plan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': globalEmail,
        'plan': plan,
        'process_type': processType, // 追加
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('プランの更新に失敗しました');
    }
  }

  Future<void> _updatePaymentStatus(bool status) async {
    final response = await http.post(
      Uri.parse('${dotenv.env['NGROK_URL']}/update/payment_status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': globalEmail,
        'payment_status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('支払いステータスの更新に失敗しました');
    }
  }

  Future<void> createSubscription() async {
    final url = Uri.parse('https://your_server_url/create-subscription');
    final response = await http.post(url,
        body: jsonEncode({'email': 'user_email'}),
        headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final clientSecret = data['client_secret'];

      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );
    } else {
      print('Error creating subscription');
    }
  }

// ＝＝＝＝＝＝＝＝＝＝＝＝＝＝20241105作業中＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
  Future<void> _fetchUserStatus() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['NGROK_URL']}/get/user_status?email=$globalEmail'),
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          nextProcessDate = userData['next_process_date'] != null
              ? DateTime.parse(userData['next_process_date'])
              : null;
          nextProcessType = userData['next_process_type'];
          nextPlan = userData['next_plan'];

          // グローバル変数も更新
          globalNextProcessDate = nextProcessDate;
          globalNextProcessType = nextProcessType;
        });
      }
    } catch (e) {
      print('ユーザー状態の取得に失敗: $e');
    }
  }

  String _getProcessMessage() {
    if (nextProcessType == null || nextProcessDate == null) return '';

    String dateStr = DateFormat('yyyy/MM/dd HH:mm').format(nextProcessDate!);

    switch (nextProcessType) {
      case 'payment':
        int amount = planPrices[globalPlan] ?? 0;
        return '次回支払い予定：$dateStr (¥$amount)';
      case 'cancel':
        return '解約予定日：$dateStr';
      case 'plan_change':
        int amount = planPrices[nextPlan ?? ''] ?? 0;
        return 'プラン変更予定日：$dateStr (¥$amount)';
      default:
        return '';
    }
  }
// ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 固定ヘッダー
          Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.white,
            child: SafeArea(
              child: Column(
                children: [
                  // 戻るボタンと料金プラン
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '料金プラン',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$globalPlan - ${globalMonthlyCost?.toInt() ?? 0}/${globalMaxMonthlyCost.toInt()}pt',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (nextProcessType != null)
                                Text(
                                  _getProcessMessage(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                ],
              ),
            ),
          ),

          // スクロール可能なコンテンツ
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '最適なプランを設定',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    ...plans.entries
                        .map((entry) => _buildPlanCard(
                              entry.key,
                              entry.value['price'],
                              entry.value['points'],
                              entry.value['description'],
                            ))
                        .toList(),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextButton(
                        onPressed: _handleCancellation,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: Text('プランを解約する'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
      String plan, int price, int points, String description) {
    bool isCurrentPlan = plan == globalPlan;

    return material.Card(
      // return とmaterial.Card でOK
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '¥$price/月',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade600, // Colors.grey[600]を修正
              ),
            ),
            Text(
              '$points ポイント/月',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrentPlan ? null : () => _handlePayment(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrentPlan ? Colors.grey : Colors.purple,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isCurrentPlan ? '現在のプラン' : 'プランを選択',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            // テスト用ボタンを追加
            ElevatedButton(
              onPressed: () async {
                try {
                  final response = await http.post(
                    Uri.parse(
                        '${dotenv.env['NGROK_URL']}/test/check-subscriptions'),
                    headers: {'Content-Type': 'application/json'},
                  );
                  print('サブスクリプションチェックレスポンス: ${response.body}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('サブスクリプションチェック実行完了')),
                  );
                } catch (e) {
                  print('チェックエラー: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('チェック実行エラー: $e')),
                  );
                }
              },
              child: Text('サブスクリプションチェック実行（テスト用）'),
            ),

            // デバッグ情報表示
            Text('現在のプラン: $globalPlan'),
            Text('次回支払日: [DBから取得]'), // この部分は実装が必要
          ],
        ),
      ),
    );
  }
}
