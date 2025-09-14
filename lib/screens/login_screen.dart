// lib/screens/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'signup_screen.dart';

import '../widgets/custom_app_bar.dart';
import '../root_tabs.dart';
import '../env.dart';
import '../services/auth_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final pw = TextEditingController();

  @override
  void dispose() { email.dispose(); pw.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (email.text.isEmpty || pw.text.isEmpty) {
      _show('이메일/비밀번호를 입력하세요.');
      return;
    }
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.text.trim(), 'password': pw.text}),
      );
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        final token = data['token'];
        if (token is String && token.isNotEmpty) {
          await AuthStorage.saveToken(token);
        }
          // ✅ RootTabs 바깥에서 왔다면 → 루트로 교체
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RootTabs(initialIndex: kTabPerson)),
          (route) => false,
        );
      } else {
        _show('로그인 실패: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      if (!mounted) return;
      _show('네트워크 오류: $e');
    }
  }

  void _show(String msg) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('안내'), content: Text(msg),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ⛔ RootTabs 밖이라도 그대로 사용 가능. 로고 → RootTabs(0)로 자동 이동.
      appBar: const CustomAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('로그인', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: email, decoration: const InputDecoration(labelText: '이메일')),
              const SizedBox(height: 8),
              TextField(controller: pw, obscureText: true, decoration: const InputDecoration(labelText: '비밀번호')),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _login, child: const Text('로그인')),

              // 👇 여기 추가
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Colors.blue,
                  ),
                  child: const Text(
                    '회원가입하러가기',
                    style: TextStyle(
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
