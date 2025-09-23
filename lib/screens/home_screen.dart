// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:planit/screens/my_schedules_screen.dart';
import 'package:planit/screens/search_page.dart';
import '../widgets/custom_app_bar.dart';
import '../services/auth_storage.dart';
import 'login_screen.dart';
import 'question_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _requireLoginThen(BuildContext context, VoidCallback action) async {
    final ok = await AuthStorage.isLoggedIn();
    if (ok) action();
    else Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                // ✏️ SearchPage로 이동할 때 검색어(value)를 전달
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SearchPage(query: value)),
                );
              }
            },
          ),
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

          // ✅ 버튼을 Card로 감싸고 아이콘/텍스트 스타일 조정
          _buildActionButton(
            context,
            icon: Icons.create,
            label: '여행 만들기',
            color: Colors.blue.shade600,
            onPressed: () => _requireLoginThen(
              context,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuestionPage()),
              ),
            ),
          ),
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