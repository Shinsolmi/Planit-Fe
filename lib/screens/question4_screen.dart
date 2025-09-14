import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'question5_screen.dart';
import '../env.dart';
import '../services/auth_storage.dart';
import '../widgets/custom_app_bar.dart'; // ✅ 공통 AppBar

class Question4Screen extends StatefulWidget {
  const Question4Screen({super.key}); // ✅ const 생성자
  @override
  _Question4ScreenState createState() => _Question4ScreenState();
}

class _Question4ScreenState extends State<Question4Screen> {
  String? selectedTheme;

  final List<String> themes = ['자연', '쇼핑', '먹방', '역사', '휴식'];

  Future<void> sendThemeToServer(String theme) async {
    final url = Uri.parse('$baseUrl/save-theme'); 
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
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
              onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const Question5Screen()),
                  );
                },
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
    );
  }
}
