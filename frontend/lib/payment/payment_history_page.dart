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
                    
                    return ListTile(
                      title: Text(record['message'] ?? ''),
                      subtitle: Text(DateFormat('yyyy/MM/dd HH:mm').format(date)),
                      trailing: amount > 0
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