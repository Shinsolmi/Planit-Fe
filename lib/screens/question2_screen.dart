import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'mypage_screen.dart';
import 'transportation_screen.dart';
import 'profile_guest_screen.dart';
import 'question3_screen.dart';

import '../widgets/custom_app_bar.dart'; // ✅ 공통 AppBar
import '../widgets/bottom_nav_bar.dart'; // ✅ 공통 BottomNavBar
import '../env.dart';

class Question2Screen extends StatefulWidget {
  @override
  _Question2ScreenState createState() => _Question2ScreenState();
}

class _Question2ScreenState extends State<Question2Screen> {
  String? selectedOption;
  int _selectedIndex = 0;

  final List<String> options = [
    '1박 2일',
    '2박 3일',
    '3박 4일',
    '4박 5일',
    '5박 6일',
  ];

  Future<void> sendDurationToServer(String duration) async {
    final url = Uri.parse('$baseUrl/save-duration'); // ⚠️ 서버 URL 교체 필요
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({'duration': duration}),
      );
      if (response.statusCode == 200) {
        print('숙박일 수 저장 성공');
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
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(), // ✅ 공통 AppBar
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('(2/5)', style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 8),
                Text('얼마나 떠나시나요?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((option) {
                    final isSelected = selectedOption == option;
                    return ChoiceChip(
                      label: Text(option),
                      selected: isSelected,
                      onSelected: (_) => setState(() => selectedOption = option),
                      selectedColor: Colors.blue,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    );
                  }).toList(),
                ),
                SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: selectedOption != null
                        ? () async {
                            await sendDurationToServer(selectedOption!);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => Question3Screen()));
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                      backgroundColor: Colors.blue,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: Text('다음', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar( // ✅ 공통 BottomNavBar
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
