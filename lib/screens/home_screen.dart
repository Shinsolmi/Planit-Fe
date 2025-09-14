import 'package:flutter/material.dart';
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

          // 예) 마이페이지도 로그인 가드
          ElevatedButton.icon(
            icon: const Icon(Icons.person),
            label: const Text('마이페이지'),
            onPressed: () => _requireLoginThen(
              context,
              () {
                // 사람 탭으로 이동하고 싶다면 RootTabs 탭 전환을 사용
                // (RootTabs 내부 화면이라면 TabsController로 setIndex(2))
                // 외부에서 접근하면 RootTabs(initialIndex: 2)로 pushAndRemoveUntil 사용
                // 여기서는 간단히 로그인만 요구하고, 사람 탭 이동은 탭바를 눌러 유도해도 OK
              },
            ),
          ),

          const SizedBox(height: 24),
          // 커뮤니티/배너/추천 섹션 등 자유롭게 추가
          // Sliver로 구성해도 되고, 위젯 분리해서 붙여도 됩니다.
        ],
      ),
      // ⛔ 바텀바는 RootTabs 전용 (여기엔 두지 않음)
    );
  }
}
