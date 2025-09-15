import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planit/widgets/custom_app_bar.dart';
import '../env.dart';
import 'recommendation_result_screen.dart'; // 추천 결과 미리보기 화면(새로 만들었다면)

class Question5Screen extends StatefulWidget {
  const Question5Screen({super.key});
  @override
  State<Question5Screen> createState() => _Question5ScreenState();
}

class _Question5ScreenState extends State<Question5Screen> {
  String? selectedSchedule; // '빼곡한일정' | '여유로운일정'
  bool _loading = false;

  final List<String> schedules = ['빼곡한일정', '여유로운일정'];

  Future<void> _savePaceAndGenerate() async {
    if (selectedSchedule == null) return;

    debugPrint('➡️ Question5: 버튼 onPressed 진입, 선택=${selectedSchedule}'); // LOG-0
    setState(() => _loading = true);
    try {
      // 1) 일정 스타일 저장: POST /ai/save-pace
      debugPrint('➡️ Question5: save-pace 호출 직전'); 
      final saveRes = await http.post(
        Uri.parse('$baseUrl/ai/save-pace'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'pace': selectedSchedule}), // ← 키 이름은 'pace'
      );
      debugPrint('⬅️ save-pace status=${saveRes.statusCode} body=${saveRes.body}');
      if (saveRes.statusCode < 200 || saveRes.statusCode >= 300) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 스타일 저장 실패 (${saveRes.statusCode})')),
        );
        return;
      }

      // 2) 추천 생성: POST /ai/schedule (몸체 불필요)
      debugPrint('➡️ Question5: /ai/schedule 호출 직전');
      final genRes = await http.post(
        Uri.parse('$baseUrl/ai/schedule'),
        headers: const {'Content-Type': 'application/json'},
      );
      debugPrint('⬅️ /ai/schedule status=${genRes.statusCode}');
      debugPrint('⬅️ /ai/schedule body=${genRes.body}');

      if (genRes.statusCode >= 200 && genRes.statusCode < 300) {
        Map<String, dynamic> plan;
        try {
          plan = jsonDecode(genRes.body) as Map<String, dynamic>;
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('추천 결과 파싱 실패')),
          );
          return;
        }

        if (!mounted) return;
        // 추천 결과 미리보기 화면으로 이동 (저장 버튼은 거기서)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecommendationResultScreen(plan: plan)),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('추천 실패: ${genRes.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('❌ Question5 에러: $e'); 
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
        child: Column(
          children: [
                const Text('(5/5)', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                const Text('어떤 여행일정을 선호하시나요?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  children: schedules.map((schedule) {
                    final isSelected = selectedSchedule == schedule;
                    return ChoiceChip(
                      label: Text(schedule),
                      selected: isSelected,
                      onSelected: (_) => setState(() => selectedSchedule = schedule),
                      selectedColor: Colors.blue,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _loading ? null : _savePaceAndGenerate,  // ← 여기!
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey,
                ),
                  child: const Text('완료', style: TextStyle(fontSize: 16)),
               ),
            ),
            if (_loading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
