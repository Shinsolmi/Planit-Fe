import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planit/widgets/custom_app_bar.dart';
import 'dart:convert';

import '../tabs_controller.dart';
import '../env.dart';
import '../services/auth_storage.dart';      // ⬅️ 토큰 저장 유틸 (있다면)
import '../root_tabs.dart';                 // ⬅️ 탭 루트로 돌아가기

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final userNameController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    userNameController.dispose();
    super.dispose();
  }

  Future<void> signupUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text;              // 복잡도/길이 제한 없음
    final confirmPassword = confirmPasswordController.text;
    final userName = userNameController.text.trim();

    if (email.isEmpty || userName.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showError('이메일/이름/비밀번호를 입력해주세요.');
      return;
    }
    if (password != confirmPassword) {
      showError('비밀번호가 일치하지 않습니다.');
      return;
    }

    try {
      final url = Uri.parse('$baseUrl/users/register');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'user_name': userName}),
      );

      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        // ⬇️ 서버가 토큰을 준다면 저장 (응답 키는 백엔드에 맞춰 변경)
        try {
          final data = jsonDecode(res.body);
          final token = data is Map ? data['token'] : null;
          if (token is String && token.isNotEmpty) {
            await AuthStorage.saveToken(token);
          }
          final name = data is Map ? (data['user_name'] ?? data['name']) : null;
          if (name is String && name.isNotEmpty) {
            await AuthStorage.saveUserName(name);
          }
        } catch (_) {}

        // 🔑 여기서 중복 바텀바 방지 처리
        final tabs = TabsController.of(context);
        if (tabs != null) {
          // 이미 RootTabs 안: 회원가입/로그인 화면만 닫고, 교통 탭으로 전환
          Navigator.of(context).pop();       // close Signup
          Navigator.of(context).maybePop();  // close Login (있으면)
          tabs.setIndex(kTabPerson);      
        } else {
          // RootTabs 밖: 루트로 교체(한 번만)
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const RootTabs(initialIndex: kTabPerson)),
            (route) => false,
          );
        }
      } else {
        showError('회원가입 실패: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      if (!mounted) return;
      showError('에러 발생: $e');
    }
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      backgroundColor: Colors.blue[300],
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text("회원가입",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 24),
                TextField(
                  controller: userNameController,
                  decoration: const InputDecoration(labelText: '이름', hintText: '이름을 입력해 주세요.'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: '이메일', hintText: '아이디를 입력해 주세요.'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '비밀번호'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '비밀번호 확인'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: signupUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text("회원가입"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context), // 로그인 화면으로 복귀
                  child: const Text("로그인하러가기"),
                ),
              ],
            ),
          ),
        ),
      ),
      // ⛔ 탭 바는 여기서 제거합니다.
      // bottomNavigationBar: _bottomNav(),
    );
  }
}
