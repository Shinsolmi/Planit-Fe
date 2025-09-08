import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'mypage_screen.dart';
import 'transportation_screen.dart';
import 'profile_guest_screen.dart';
import 'question4_screen.dart';

import '../widgets/custom_app_bar.dart'; // ✅ 공통 AppBar
import '../widgets/bottom_nav_bar.dart'; // ✅ 공통 BottomNavBar
import '../env.dart';

class Question3Screen extends StatefulWidget {
  @override
  _Question3ScreenState createState() => _Question3ScreenState();
}

class _Question3ScreenState extends State<Question3Screen> {
  String? selectedTravelType;
  int _selectedIndex = 0;

  final List<String> travelTypes = [
    '혼자', '부모님', '연인', '배우자', '친구', '아이와 함께', '지인'
  ];

  Future<void> sendCompanionToServer(String companion) async {
    final url = Uri.parse('$baseUrl/save-companion'); // ⚠️ 서버 URL 교체 필요
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({'companion': companion}),
      );
      if (response.statusCode == 200) {
        print('동행자 정보 저장 성공');
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
        child: Column(
          children: [
            Text('(3/5)', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('누구와 떠나시나요?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: travelTypes.map((type) {
                final isSelected = selectedTravelType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (_) => setState(() => selectedTravelType = type),
                  selectedColor: Colors.blue,
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                );
              }).toList(),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: selectedTravelType != null
                  ? () async {
                      await sendCompanionToServer(selectedTravelType!);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => Question4Screen()));
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
      bottomNavigationBar: BottomNavBar( // ✅ 공통 BottomNavBar
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
