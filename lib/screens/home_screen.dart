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
          const Text('여행을 시작해 볼까요?'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.create),
            label: const Text('여행 만들기'),
            onPressed: () => _requireLoginThen(
              context,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuestionPage()),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.event_note),
            label: const Text('내 일정'),
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
}