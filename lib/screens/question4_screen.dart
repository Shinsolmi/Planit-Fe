import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'mypage_screen.dart';
import 'transportation_screen.dart';
import 'profile_guest_screen.dart';
import 'question5_screen.dart';
import '../env.dart';

class Question4Screen extends StatefulWidget {
  @override
  _Question4ScreenState createState() => _Question4ScreenState();
}

class _Question4ScreenState extends State<Question4Screen> {
  String? selectedTheme;
  int _selectedIndex = 0;

  final List<String> themes = ['자연', '쇼핑', '먹방', '역사', '휴식'];

  Future<void> sendThemeToServer(String theme) async {
    final url = Uri.parse('$baseUrl/save-theme'); // 수정 필요
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({'theme': theme}),
      );
      if (response.statusCode == 200) {
        print('테마 정보 저장 성공');
      } else {
        print('저장 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('에러 발생: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TransportSelectionPage()));
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        title: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileGuestScreen())),
          child: Text('PLANIT'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('(4/5)', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('원하는 테마는 무엇인가요?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: themes.map((theme) {
                final isSelected = selectedTheme == theme;
                return ChoiceChip(
                  label: Text(theme),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      selectedTheme = theme;
                    });
                  },
                  selectedColor: Colors.blue,
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                );
              }).toList(),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: selectedTheme != null
                  ? () async {
                      await sendThemeToServer(selectedTheme!);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => Question5Screen()));
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                backgroundColor: Colors.blue,
                disabledBackgroundColor: Colors.grey,
              ),
              child: Text('다음', style: TextStyle(fontSize: 16)),
            ),
          ],
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
          BottomNavigationBarItem(icon: Icon(Icons.directions_transit), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}
