import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'question4_screen.dart';

import '../widgets/custom_app_bar.dart'; // ✅ 공통 AppBar
import '../env.dart';
import '../services/auth_storage.dart';

class Question3Screen extends StatefulWidget {
  const Question3Screen({super.key}); // ✅ const 생성자
  @override
  _Question3ScreenState createState() => _Question3ScreenState();
}

class _Question3ScreenState extends State<Question3Screen> {
  String? selectedTravelType;
  bool _loading = false;

  final List<String> travelTypes = [
    '혼자', '부모님', '가족', '연인/배우자', '친구', '아이와 함께', '지인', '애완동물', '직장/단체'
  ];

  Future<void> _saveCompanionAndNext() async {
    if (selectedTravelType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('동행자를 선택해 주세요.')));
      return;
    }
    setState(() => _loading = true);
    try {
      debugPrint('➡️ Q3 /ai/save-companion 직전 companion=$selectedTravelType');
      final res = await http.post(
        Uri.parse('$baseUrl/ai/save-companion'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'companion': selectedTravelType}),
      );
      debugPrint('⬅️ Q3 status=${res.statusCode} body=${res.body}');
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const Question4Screen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('동행자 저장 실패: ${res.statusCode}')));
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
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _loading ? null :  _saveCompanionAndNext,  // ← 여기!
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

