import 'package:flutter/material.dart';

class ProfileUserScreen extends StatelessWidget {
  final String userName = "이름"; // 실제 앱에서는 로그인 정보에서 가져오기

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
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue[400],
                      child: Icon(Icons.camera_alt, size: 40),
                    ),
                    SizedBox(height: 12),
                    Text(userName, style: TextStyle(fontSize: 16)),
                  ],
                ),
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
