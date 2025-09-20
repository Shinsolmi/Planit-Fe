import 'package:flutter/material.dart';
import 'package:planit/screens/my_schedules_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../services/auth_storage.dart';      // isLoggedIn()
import 'login_screen.dart';
import 'question_screen.dart';               // 로그인 후 진행

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
          const Text('PLANIT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('여행을 시작해 볼까요?'),
          const SizedBox(height: 16),

          // 🔵 여행 만들기: 로그인 필요로 변경
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
          // ✅ 내 일정으로 이동 (마이페이지 버튼 제거하고 교체)
          ElevatedButton.icon(
            icon: const Icon(Icons.event_note),
            label: const Text('내 일정'),
            onPressed: () => _requireLoginThen(
              context,
              () {
                // TODO: 너희 프로젝트의 "내 일정 목록/화면"으로 변경
                // 예1) 목록 화면이 따로 있으면: MySchedulesScreen()
                // 예2) 저장된 일정 요약 화면이면: CompletionScreen()
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
