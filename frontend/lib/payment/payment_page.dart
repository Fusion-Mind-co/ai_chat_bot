// payment_page.dart

import 'dart:async';
import 'package:chatbot/app.dart';
import 'package:chatbot/globals.dart';
import 'package:chatbot/payment/payment_history_page.dart';
import 'package:chatbot/socket_service.dart';
import 'package:flutter/material.dart' hide Card; // Materialの'Card'を隠す
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:flutter/material.dart' as material show Card;
import 'package:intl/intl.dart';

class PaymentPage extends StatefulWidget {
  final bool isInitialAccess; // 初回アクセスフラグを追加

  PaymentPage({this.isInitialAccess = false}); // デフォルトはfalse

  @override
  PaymentPageState createState() => PaymentPageState();
}

class PaymentPageState extends State<PaymentPage> {
  DateTime? nextProcessDate;
  String? nextProcessType;
  String? nextPlan;
  String? selectedPlan;

  @override
  void initState() {
    super.initState();
    _fetchUserStatus();

    // WebSocketのリスナーを追加
    SocketService.addStatusUpdateListener(_handleStatusUpdate);
  }

  // WebSocketイベントのハンドラーを定義
  void _handleStatusUpdate(dynamic data) async {
    if (data['email'] == globalEmail && mounted) {
      await _fetchUserStatus();

      // UIに通知
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('アカウント状態が更新されました'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // WebSocketのリスナーを削除
    SocketService.removeStatusUpdateListener(_handleStatusUpdate);
    super.dispose();
  }

  final Map<String, Map<String, dynamic>> plans = {
    'Standard': {
      'price': planPrices['Standard'],
      'description': 'ChatGPT 4o 使い放題プラン',
    },
  };

  // 支払い処理中フラグを追加
  bool _isProcessingPayment = false;

  Future<void> _handlePayment(String plan) async {
    // 処理中なら早期リターン
    if (_isProcessingPayment) {
      print('支払い処理中のため、リクエストをスキップします');
      return;
    }

    print('\n=== 支払い処理開始 ===');
    print('選択プラン: $plan');

    setState(() {
      selectedPlan = plan;
      _isProcessingPayment = true; // 処理開始
    });

    try {
      await _handleInitialPayment(plan);
      print('決済処理完了');

      print('プラン更新開始: $plan');
      final response = await http.post(
        Uri.parse('$serverUrl/update/plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'email': globalEmail, 'plan': plan, 'process_type': 'payment'}),
      );
      print('サーバーレスポンス: ${response.statusCode}');
      print('レスポンスボディ: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        setState(() {
          globalPlan = plan;
          globalNextProcessDate =
              DateTime.parse(responseData['next_process_date']);
          globalNextProcessType = 'payment';

          if (responseData['selectedmodel'] != null) {
            globalSelectedModel = responseData['selectedmodel'];
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('プランの更新が完了しました')),
          );
        }

        await _fetchUserStatus();
        await AppState.refreshState();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'プランの更新に失敗しました');
      }
    } catch (e) {
      print('エラー発生:');
      print('  タイプ: ${e.runtimeType}');
      print('  メッセージ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false; // 処理完了
        });
      }
    }
  }

  Future<void> _processPayment(Map<String, dynamic> paymentIntentData) async {
    if (selectedPlan == null) {
      throw Exception('選択されたプランが見つかりません');
    }

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

      // 支払い完了後に支払い記録を作成
      await _recordSuccessfulPayment(
        paymentIntentData['payment_intent_id'],
        selectedPlan!,
        plans[selectedPlan]!['price'],
      );
    } catch (e) {
      print('決済処理エラー: $e');
      throw Exception('決済処理に失敗しました: $e');
    }
  }

  // 初期決済処理
  Future<void> _handleInitialPayment(String plan) async {
    final planDetails = plans[plan];

    // 1. PaymentIntent作成
    final response = await http.post(
      Uri.parse('$serverUrl/create-payment-intent'),
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

    // UIの更新
    await AppState.refreshState();
  }

  Future<void> _recordSuccessfulPayment(
      String paymentIntentId, String plan, int amount) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/record-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': globalEmail,
          'plan': plan,
          'amount': amount,
          'transaction_id': paymentIntentId,
          'message': '有料プラン加入支払い'
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('支払い記録の作成に失敗しました');
      }
    } catch (e) {
      print('支払い記録作成エラー: $e');
      // 支払い自体は成功しているので、記録のエラーはユーザーには表示しない
    }
  }

  // 解約処理
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

    // 解約に必要なテーブルデータを渡す

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/reserve-cancellation'),
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
        // UIの更新
        await AppState.refreshState();
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

  //
  Future<void> _updateUserPlan(String plan, {String? processType}) async {
    final response = await http.post(
      Uri.parse('$serverUrl/update/plan'),
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
      Uri.parse('$serverUrl/update/payment_status'),
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

  Future<void> _fetchUserStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/get/user_status?email=$globalEmail'),
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          globalPlan = userData['plan'];

          // モデルの更新を追加
          if (userData['selectedmodel'] != null) {
            globalSelectedModel = userData['selectedmodel'];
          }

          nextProcessDate = userData['next_process_date'] != null
              ? DateTime.parse(userData['next_process_date'])
              : null;
          nextProcessType = userData['next_process_type'];
          nextPlan = userData['next_plan'];

          globalNextProcessDate = nextProcessDate;
          globalNextProcessType = nextProcessType;
        });

        // プラン変更を検知したらスナックバーで通知
        if (mounted && userData['plan'] == 'Free' && globalPlan != 'Free') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '自動支払いに失敗したため、無料プランに変更されました。\n有料プランに再度加入するには、お支払い情報の再登録が必要です。'),
              duration: Duration(seconds: 10),
            ),
          );
        }
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
        return '$globalPlan プラン終了日：$dateStr';
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
          // ヘッダー部分
          Container(
            child: SafeArea(
              child: Column(
                children: [
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
                                '$globalPlan',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                              ),
                              if (nextProcessType != null)
                                Text(
                                  _getProcessMessage(),
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.blue[700]),
                                ),
                            ],
                          ),
                        ),
                        // 履歴ボタンをテキストボタンに変更
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentHistoryPage(),
                              ),
                            );
                          },
                          child: Text(
                            '支払い履歴',
                            style: TextStyle(color: Colors.blue),
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

          // メインコンテンツ
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '有料プラン',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (widget.isInitialAccess)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/home');
                          },
                          child: Text(
                            '無料プランで始める',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: 20),
                    ...plans.entries
                        .map((entry) => _buildPlanCard(
                              entry.key,
                              entry.value['price'],
                            ))
                        .toList(),
                    if (globalPlan != 'Free')
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(top: 16),
                        child: OutlinedButton(
                          onPressed: _handleCancellation,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[700],
                            side: BorderSide(color: Colors.red[700]!),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'プランを解約する',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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

  Widget _buildPlanCard(String plan, int price) {
    bool isCurrentPlan = plan == globalPlan;
    bool isDisabled = isCurrentPlan || _isProcessingPayment; // 無効化条件を追加

    return material.Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              '¥$price/月',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isDisabled ? null : () => _handlePayment(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Theme.of(context).disabledColor,
                  disabledForegroundColor: Colors.white70,
                  elevation: 2,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isProcessingPayment ? '処理中...' : '申し込む', // ボタンのテキストを動的に変更
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
