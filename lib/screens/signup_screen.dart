import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 본인이 만든 화면 import 추가
import 'question_screen.dart'; // 홈
import 'transportation_screen.dart'; // 교통
import 'profile_guest_screen.dart'; // 마이페이지

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();

  int _selectedIndex = 3; // 기본: 마이페이지 선택됨

  Future<void> signupUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final userName = userNameController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || userName.isEmpty) {
      showError('모든 항목을 입력해주세요.');
      return;
    }

    if (password != confirmPassword) {
      showError('비밀번호가 일치하지 않습니다.');
      return;
    }

    try {
      final url = Uri.parse('https://eighty-years-own.loca.lt/users/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'user_name': userName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('회원가입 성공: $responseData');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileGuestScreen()),
        );
      } else {
        showError('회원가입 실패: ${response.body}');
      }
    } catch (e) {
      showError('에러 발생: $e');
    }
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QuestionPage()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TransportSelectionPage()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfileGuestScreen()));
    }
    // index == 2는 현재 기능 없음
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QuestionPage()));
          },
          child: Text(
            'PLANIT',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      backgroundColor: Colors.blue[300],
      body: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text("회원가입", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                SizedBox(height: 24),
                TextField(
                  controller: userNameController,
                  decoration: InputDecoration(labelText: '이름', hintText: '이름을 입력해 주세요.'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: '이메일', hintText: '아이디를 입력해 주세요.'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: '비밀번호'),
                ),
                SizedBox(height: 8),
                Text('비밀번호는 최소 8자, 문자, 숫자, 특수 문자를 포함해야 합니다.', style: TextStyle(fontSize: 10)),
                SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: '비밀번호 확인'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: signupUser,
                  child: Text("회원가입"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: Size(double.infinity, 40),
                  ),
                ),
                SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("로그인하러가기"),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.blue,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.train), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}
