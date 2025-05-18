import 'package:flutter/material.dart';
import 'login_screen.dart';

class ProfileGuestScreen extends StatelessWidget {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PLANIT', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
              SizedBox(height: 32),
              Row(
                children: [
                  CircleAvatar(radius: 30, child: Icon(Icons.person)),
                  SizedBox(width: 12),
                  Text('로그인이 필요합니다.'),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                    },
                    child: Text('로그인'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  )
                ],
              ),
              SizedBox(height: 40),
              Text('예정된 일정'),
              SizedBox(height: 12),
              Text('지난 일정 관리'),
              SizedBox(height: 12),
              Text('저장한 대중교통 팁'),
              SizedBox(height: 12),
              Text('작성한 후기'),
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
