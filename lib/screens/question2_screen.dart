import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'question3_screen.dart';
import '../widgets/custom_app_bar.dart'; // ✅ 공통 AppBar
import '../env.dart';
import '../services/auth_storage.dart';

class Question2Screen extends StatefulWidget {
  const Question2Screen({super.key}); // ✅ const 생성자
  @override
  _Question2ScreenState createState() => _Question2ScreenState();
}

class _Question2ScreenState extends State<Question2Screen> {
  String? selectedOption;
  bool _loading = false;

  final List<String> options = [
    '1박 2일',
    '2박 3일',
    '3박 4일',
    '4박 5일',
    '5박 6일',
  ];

  Future<void> _saveDurationAndNext() async {
    if (selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('숙박일 수를 선택해 주세요.')));
      return;
    }
    setState(() => _loading = true);
    try {
      debugPrint('➡️ Q2 /ai/save-duration 직전 days=$selectedOption');
      final res = await http.post(
        Uri.parse('$baseUrl/ai/save-duration'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'duration': selectedOption}),
      );
      debugPrint('⬅️ Q2 status=${res.statusCode} body=${res.body}');
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const Question3Screen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('기간 저장 실패: ${res.statusCode}')));
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
      appBar: CustomAppBar(), // ✅ 공통 AppBar
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                Text('(2/5)', style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 8),
                Text('얼마나 떠나시나요?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 24),
                ],
              ),
            ),
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
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: _loading ? null : _saveDurationAndNext,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                        backgroundColor: Colors.blue,
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: const Text('다음', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
                if (_loading) const Center(child: CircularProgressIndicator()),
              ],
            ),
        ),
    );
  }
}
