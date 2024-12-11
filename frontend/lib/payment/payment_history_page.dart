// payment_history_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:chatbot/globals.dart';

class PaymentHistoryPage extends StatefulWidget {
  @override
  _PaymentHistoryPageState createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/get/payment_history?email=$globalEmail'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _history = List<Map<String, dynamic>>.from(data['history']);
          _isLoading = false;
        });
      } else {
        throw Exception('履歴の取得に失敗しました');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  // 履歴アイテムのウィジェットを作成する関数
  Widget _buildHistoryItem(Map<String, dynamic> record) {
    final date = DateTime.parse(record['processed_date']);
    final amount = record['amount'];
    final message = record['message'] ?? '';
    final isFailure = message.contains('失敗');

    return ListTile(
      title: Text(
        message,
        style: TextStyle(
          color: isFailure ? Colors.red : Colors.black87,
          fontWeight: isFailure ? FontWeight.normal : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        DateFormat('yyyy/MM/dd HH:mm').format(date),
        style: TextStyle(
          color: Colors.black54,
        ),
      ),
      trailing: (amount != null && !isFailure) // 金額がnullでない かつ 失敗でない場合のみ表示
          ? Text(
              '¥${NumberFormat("#,###").format(amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            )
          : null,
    );
  }
// payment_history_page.dart のListTile部分を修正

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('支払い履歴'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(child: Text('支払い履歴がありません'))
              : ListView.separated(
                  itemCount: _history.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final record = _history[index];
                    final date = DateTime.parse(record['processed_date']);
                    final amount = record['amount'];
                    final message = record['message'] ?? '';

                    // 支払い失敗または解約の場合は金額を表示しない
                    final shouldShowAmount = amount != null &&
                        !message.contains('失敗') &&
                        !message.contains('解約');

                    return ListTile(
                      title: Text(
                        message,
                        style: TextStyle(
                          color: message.contains('失敗')
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                      subtitle:
                          Text(DateFormat('yyyy/MM/dd HH:mm').format(date)),
                      trailing: shouldShowAmount
                          ? Text(
                              '¥${amount.toString()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            )
                          : null,
                    );
                  },
                ),
    );
  }
}
