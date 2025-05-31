import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'mypage_screen.dart';
import 'question_screen.dart';
import 'profile_guest_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import 'transport_tip_detail_screen.dart';

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

  void _openTipDetail(String transport) async {
    final url = Uri.parse('https://your-backend.com/api/transport-tips?type=$transport'); // ✅ 백엔드 URL 수정

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tipText = data['tip'] ?? '팁이 없습니다.';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransportTipDetailScreen(
              transportType: transport,
              tip: tipText,
            ),
          ),
        );
      } else {
        _showErrorSnackBar('불러오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('에러 발생: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('교통수단 선택', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            ...transportOptions.map((option) {
              return ListTile(
                leading: Icon(option['icon'], size: 30),
                title: Text(option['label'], style: TextStyle(fontSize: 18)),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _openTipDetail(option['label']),
              );
            }).toList(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'mypage_screen.dart';
import 'question_screen.dart';
import 'profile_guest_screen.dart';

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
