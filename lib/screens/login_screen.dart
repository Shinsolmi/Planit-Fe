import 'package:flutter/material.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[300],
      body: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("PLANIT", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
              SizedBox(height: 32),
              Text("로그인", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
              SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(labelText: '이메일', hintText: '아이디를 입력해 주세요.'),
              ),
              SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: '비밀번호', hintText: '비밀번호를 입력해 주세요.'),
              ),
              SizedBox(height: 8),
              Text('비밀번호는 최소 8자, 문자, 숫자, 특수 문자를 포함해야 합니다.', style: TextStyle(fontSize: 10)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // 로그인 처리
                },
                child: Text("로그인"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 40),
                ),
              ),
              SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SignupScreen()));
                },
                child: Text("계정이 없으신가요?"),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: bottomNav(),
    );
  }

   Widget bottomNav() {
    return BottomNavigationBar(
      backgroundColor: Colors.blue, // 배경 색상
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.train), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
      ],
    );
  }
}
