// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:planit/screens/my_schedules_screen.dart';
import 'package:planit/screens/search_page.dart';
import '../widgets/custom_app_bar.dart';
import '../services/auth_storage.dart';
import 'login_screen.dart';
import 'question_screen.dart'; // QuestionPage (Q1)
import '../env.dart'; // baseUrl 사용을 위해 추가

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _requireLoginThen(BuildContext context, VoidCallback action) async {
    final ok = await AuthStorage.isLoggedIn();
    if (ok) action();
    else Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  // 👇 서버의 진행 상태를 초기화하고 무조건 Q1으로 이동
  Future<void> _startNewTrip(BuildContext context) async {
    final token = await AuthStorage.getToken();
    
    if (token != null && token.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('$baseUrl/ai/clear-progress'),
          headers: {'Authorization': 'Bearer $token'},
        );
        debugPrint('AI progress cleared on server.');
      } catch (e) {
        debugPrint('Warning: Failed to clear AI progress: $e');
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuestionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(), 
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ 검색창 CSS를 원래대로 복구 (Card 위젯과 Padding 제거)
          TextField(
            decoration: const InputDecoration(
              hintText: '도시, 장소 등을 검색해 보세요',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            onSubmitted: (String value) {
              if (value.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SearchPage(query: value)),
                );
              }
            },
          ),
          // ❌ 이전 검색창 Card 위젯을 제거했으므로, 여기서 SizedBox를 조정할 수 있습니다.
          const SizedBox(height: 8), 

          Text(
            '여행을 시작해 볼까요?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // '여행 만들기' 버튼: 무조건 Q1으로 이동하는 함수 호출
          _buildActionButton(
            context,
            icon: Icons.create,
            label: '여행 만들기',
            color: Colors.blue.shade600,
            onPressed: () => _requireLoginThen(
              context,
              () => _startNewTrip(context),
            ),
          ),
          
          // '내 일정' 버튼
          _buildActionButton(
            context,
            icon: Icons.event_note,
            label: '내 일정',
            color: Colors.lightBlue.shade300,
            onPressed: () => _requireLoginThen(
              context,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MySchedulesScreen(), 
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  // ✅ _buildActionButton 함수는 유지하여 버튼 스타일을 개선된 상태로 둡니다.
  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}