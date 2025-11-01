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
    '일본': ['도쿄', '오사카', '교토', '후쿠오카', '시즈오카', '나고야', '삿포로', '오키나와', '나가사키']
  };

  String? selectedCity;
  bool _loading = false;

  Future<void> _saveCityAndNext() async {
    if (selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('도시를 선택해 주세요.')),
      );
      return;
    }

    try {
      setState(() => _loading = true);
      debugPrint('➡️ Question1: /ai/save-city 호출 직전 city=$selectedCity');

      final url = Uri.parse('$baseUrl/ai/save-city');
      final res = await http.post(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'city': selectedCity}),
      );

      debugPrint('⬅️ /ai/save-city status=${res.statusCode}');
      debugPrint('⬅️ /ai/save-city body=${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const Question2Screen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('도시 저장 실패: ${res.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('❌ /ai/save-city 에러: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
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
                onPressed: _loading ? null : _saveCityAndNext,  // ← 여기!
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
