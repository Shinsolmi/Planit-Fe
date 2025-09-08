import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'mypage_screen.dart';
import 'transportation_screen.dart';
import 'profile_guest_screen.dart';
import 'completion_screen.dart';
import '../env.dart';

class Question5Screen extends StatefulWidget {
  @override
  _Question5ScreenState createState() => _Question5ScreenState();
}

class _Question5ScreenState extends State<Question5Screen> {
  String? selectedSchedule;
  int _selectedIndex = 0;

  final List<String> schedules = ['빼곡한일정', '여유로운일정'];

  Future<void> sendSchedulePreferenceToServer(String scheduleType) async {
    final url = Uri.parse('$baseUrl/save-schedule'); // 수정 필요
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({'schedule': scheduleType}),
      );
      if (response.statusCode == 200) {
        print('일정 스타일 저장 성공');
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
            Text('(5/5)', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('어떤 여행일정을 선호하시나요?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: schedules.map((schedule) {
                final isSelected = selectedSchedule == schedule;
                return ChoiceChip(
                  label: Text(schedule),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      selectedSchedule = schedule;
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
              onPressed: selectedSchedule != null
                  ? () async {
                      await sendSchedulePreferenceToServer(selectedSchedule!);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => CompletionScreen()));
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                backgroundColor: Colors.blue,
                disabledBackgroundColor: Colors.grey,
              ),
              child: Text('완료', style: TextStyle(fontSize: 16)),
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
