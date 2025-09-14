import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'question2_screen.dart';
import '../widgets/custom_app_bar.dart'; 
import '../env.dart';
import '../services/auth_storage.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key}); // ✅ const 생성자
  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final Map<String, List<String>> cityCategories = {
    '일본': ['도쿄', '오사카', '후쿠오카', '시즈오카', '나고야', '삿포로', '오키나와'],
    '중국': ['충칭', '상하이', '베이징'],
  };

  String? selectedCity;

  // 🔵 서버로 도시 전송
  Future<void> sendSelectedCityToServer(String city) async {
    final url = Uri.parse('$baseUrl/save-city'); // ⚠️ URL 수정 필요
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
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const Question2Screen()),
                  );
                },
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
    );
  }
}
