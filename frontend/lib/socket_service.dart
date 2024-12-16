// lib/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:chatbot/globals.dart';
import 'package:chatbot/app.dart';
import 'package:flutter/material.dart';

class SocketService {
  static IO.Socket? _socket;
  
  // WebSocketイベントの購読を追加するメソッド
  static void addStatusUpdateListener(Function(dynamic) callback) {
    _socket?.on('user_status_update', callback);
  }
  
  // WebSocketイベントの購読を解除するメソッド
  static void removeStatusUpdateListener(Function(dynamic) callback) {
    _socket?.off('user_status_update', callback);
  }

  static void initSocket() {
    if (_socket != null) return;
    
    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.on('connect', (_) {
      print('WebSocket Connected: ${DateTime.now()}');
    });

    _socket!.on('disconnect', (_) {
      print('WebSocket Disconnected: ${DateTime.now()}');
    });

    _socket!.on('connect_error', (error) {
      print('WebSocket Connection Error: $error');
    });

    _socket!.connect();
  }

  static void dispose() {
    _socket?.disconnect();
    _socket = null;
  }
}