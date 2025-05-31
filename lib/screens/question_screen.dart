import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'mypage_screen.dart';
import 'transportation_screen.dart';
import 'profile_guest_screen.dart';
import 'question2_screen.dart';

import '../widgets/custom_app_bar.dart'; 
import '../widgets/bottom_nav_bar.dart';

class QuestionPage extends StatefulWidget {
  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final Map<String, List<String>> cityCategories = {
    '일본': ['도쿄', '오사카', '후쿠오카', '시즈오카', '나고야', '삿포로', '오키나와'],
    '중국': ['충칭', '상하이', '베이징'],
  };

  String? selectedCity;
  int _selectedIndex = 0;

  // 🔵 서버로 도시 전송
  Future<void> sendSelectedCityToServer(String city) async {
    final url = Uri.parse('https://your-api-url.com/save-city'); // ⚠️ URL 수정 필요
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({'city': city}),
      );
      if (response.statusCode == 200) {
        print('도시 정보 저장 성공');
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
      appBar: CustomAppBar(), // ✅ 공통 AppBar 사용
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  Text('(1/5)', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('떠나고 싶은 도시는?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('도시 1곳을 선택해주세요.', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 24),
                ],
              ),
            ),
            ...cityCategories.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.value.map((city) {
                      final isSelected = selectedCity == city;
                      return ChoiceChip(
                        label: Text(city),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            selectedCity = city;
                          });
                        },
                        selectedColor: Colors.blue,
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),
                ],
              );
            }).toList(),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: selectedCity != null
                    ? () async {
                        await sendSelectedCityToServer(selectedCity!); // 🔵 서버로 저장
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => Question2Screen()),
                        );
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
      ),
      bottomNavigationBar: BottomNavBar( // ✅ 공통 BottomNavBar 사용
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'mypage_screen.dart';
import 'transportation_screen.dart';
import 'profile_guest_screen.dart'; 

class QuestionPage extends StatefulWidget {
  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final Map<String, List<String>> cityCategories = {
    '일본': ['도쿄', '오사카', '후쿠오카', '시즈오카', '나고야', '삿포로', '오키나와'],
    '중국': ['충칭', '상하이', '베이징'],
  };

  String? selectedCity;
  int _selectedIndex = 0; // 현재 선택된 bottom nav 인덱스

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TransportSelectionPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MypageScreen()),
      );
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileGuestScreen()),
            );
          },
          child: Text('PLANIT'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  Text('(1/5)', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('떠나고 싶은 도시는?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('도시 1곳을 선택해주세요.', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 24),
                ],
              ),
            ),
            ...cityCategories.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.value.map((city) {
                      final isSelected = selectedCity == city;
                      return ChoiceChip(
                        label: Text(city),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            selectedCity = city;
                          });
                        },
                        selectedColor: Colors.blue,
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),
                ],
              );
            }).toList(),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: selectedCity != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => QuestionPage()),
                        );
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
