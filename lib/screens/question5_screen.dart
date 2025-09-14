import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planit/widgets/custom_app_bar.dart';
import 'dart:convert';

import 'completion_screen.dart';
import '../env.dart';
import '../services/auth_storage.dart';

class Question5Screen extends StatefulWidget {
  const Question5Screen({super.key}); // ✅ const 생성자
  @override
  _Question5ScreenState createState() => _Question5ScreenState();
}

class _Question5ScreenState extends State<Question5Screen> {
  String? selectedSchedule;

  final List<String> schedules = ['빼곡한일정', '여유로운일정'];

  Future<void> sendSchedulePreferenceToServer(String scheduleType) async {
    final url = Uri.parse('$baseUrl/save-schedule'); // 수정 필요
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({'schedule': scheduleType}),
      );
      if (response.statusCode == 200) {
        print('일정 스타일 저장 성공');
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
            Text('(5/5)', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('어떤 여행일정을 선호하시나요?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: schedules.map((schedule) {
                final isSelected = selectedSchedule == schedule;
                return ChoiceChip(
                  label: Text(schedule),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      selectedSchedule = schedule;
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
              onPressed: selectedSchedule != null
                  ? () async {
                      await sendSchedulePreferenceToServer(selectedSchedule!);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => CompletionScreen()));
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                backgroundColor: Colors.blue,
                disabledBackgroundColor: Colors.grey,
              ),
              child: Text('완료', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
