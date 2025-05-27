import 'package:flutter/material.dart';
import 'mypage_screen.dart';
import 'question_screen.dart';
import 'profile_guest_screen.dart'; // ✅ ProfileGuestScreen import 추가

class TransportSelectionPage extends StatefulWidget {
  @override
  _TransportSelectionPageState createState() => _TransportSelectionPageState();
}

class _TransportSelectionPageState extends State<TransportSelectionPage> {
  final List<Map<String, dynamic>> transportOptions = [
    {'icon': Icons.local_taxi, 'label': '택시'},
    {'icon': Icons.directions_bus, 'label': '버스'},
    {'icon': Icons.subway, 'label': '지하철'},
    {'icon': Icons.train, 'label': '기차'},
  ];

  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => QuestionPage()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MypageScreen()));
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Center(
        child: Container(
          width: 300,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfileGuestScreen()), // ✅ PLANIT 클릭 시 이동
                  );
                },
                child: Text(
                  'PLANIT',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                '교통수단 선택',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20),
              ...transportOptions.map((option) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(option['icon'], size: 30),
                      SizedBox(width: 10),
                      Text(option['label'], style: TextStyle(fontSize: 16)),
                    ],
                  ),
                );
              }).toList(),
            ],
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
