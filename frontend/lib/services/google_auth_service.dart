// google_auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../globals.dart';
import 'package:chatbot/chat_page/api/api_config.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,  // 追加
  );

  Future<bool> signInWithGoogle() async {
    try {
      print('Starting Google Sign In...');
      
      // 既存のサインインをクリア
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign In cancelled by user');
        return false;
      }

      print('Getting Google Auth...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('Authentication Details:');
      print('- Access Token: ${googleAuth.accessToken}');
      print('- ID Token: ${googleAuth.idToken}');
      print('- Email: ${googleUser.email}');
      print('- Display Name: ${googleUser.displayName}');

      // アクセストークンがあれば成功とみなす
      if (googleAuth.accessToken != null) {
        globalEmail = googleUser.email;
        return true;
      }

      return false;
    } catch (e) {
      print('Google Sign-In Error: $e');
      print(StackTrace.current);
      return false;
    }
  }
}