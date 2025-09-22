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
  bool _loading = false;

  final List<String> themes = ['힐링', '관광', '쇼핑', '식도락', '액티비티', '역사 · 문화 탐방', '포토 스팟', '로맨틱'];


  Future<void> _saveThemeAndNext() async {
    if (selectedTheme == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('테마를 선택해 주세요.')));
      return;
    }
    setState(() => _loading = true);
    try {
      debugPrint('➡️ Q4 /ai/save-theme 직전 theme=$selectedTheme');
      final res = await http.post(
        Uri.parse('$baseUrl/ai/save-theme'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'theme': selectedTheme}),
      );
      debugPrint('⬅️ Q4 status=${res.statusCode} body=${res.body}');
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const Question5Screen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('테마 저장 실패: ${res.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('네트워크 오류: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
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
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _loading ? null : _saveThemeAndNext,  // ← 여기!
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: const Text('다음', style: TextStyle(fontSize: 16)),
              ),
            ),
            if (_loading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
