import 'package:flutter/material.dart';
import 'services/auth_storage.dart';
import 'screens/login_screen.dart';

// 탭 화면들
import 'screens/home_screen.dart';                 // ⬅️ 새로 탭에 편입
import 'screens/question_screen.dart';             // 여행 만들기(질문 플로우)
import 'screens/transport_selection_page.dart';    // 교통
import 'screens/profile_user_screen.dart';         // 사람(게스트/로그인 분기 내장)

import 'tabs_controller.dart';

// 탭 인덱스 상수
const kTabHome      = 0;
const kTabCreate    = 1; // 여행 만들기
const kTabTransport = 2;
const kTabPerson    = 3;

class RootTabs extends StatefulWidget {
  const RootTabs({super.key, this.initialIndex = kTabHome});
  final int initialIndex;

  @override
  State<RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<RootTabs> {
  // 각 탭의 네비게이터 키
  final _navKeys = {
    kTabHome:      GlobalKey<NavigatorState>(),
    kTabCreate:    GlobalKey<NavigatorState>(),
    kTabTransport: GlobalKey<NavigatorState>(),
    kTabPerson:    GlobalKey<NavigatorState>(),
  };

  late int _index = widget.initialIndex;

  
  // 각 탭을 Navigator로 감싸기 (첫 라우트는 그 탭의 루트 화면)
  late final List<Widget> _pages = [
    Navigator(
      key: _navKeys[kTabHome],
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const HomeScreen()),
    ),
    Navigator(
      key: _navKeys[kTabCreate],
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => QuestionPage()),
    ),
    Navigator(
      key: _navKeys[kTabTransport],
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const TransportSelectionPage()),
    ),
    Navigator(
      key: _navKeys[kTabPerson],
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const ProfileUserScreen()),
    ),
  ];

Future<void> _handleTap(int i) async {
  // 같은 탭 재클릭 시 루트로
  if (i == _index) {
    _navKeys[i]!.currentState?.popUntil((r) => r.isFirst);
    return;
  }

  // 여행만들기(로그인 가드)
  if (i == kTabCreate) {
    final loggedIn = await AuthStorage.isLoggedIn();
    if (!loggedIn) {
      // 1) 먼저 여행만들기 탭으로 전환
      if (mounted && _index != kTabCreate) {
        setState(() => _index = kTabCreate);
      }
      // 2) 그 탭의 중첩 Navigator에 로그인 화면 푸시 (바텀바 유지)
      _navKeys[kTabCreate]!.currentState?.push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return; // 탭 인덱스 변경 끝
    }
  }

  if (mounted) setState(() => _index = i);
}


  Future<bool> _onWillPop() async {
    // 뒤로가기 시: 현재 탭의 네비게이터 스택을 먼저 pop
    final nav = _navKeys[_index]!.currentState!;
    if (nav.canPop()) {
      nav.pop();
      return false;
    }
    return true; // 더이상 pop할 게 없으면 앱 나가기
  }

  @override
  Widget build(BuildContext context) {
    return TabsController(
      setIndex: (i) => _handleTap(i),
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          body: IndexedStack(index: _index, children: _pages),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _index,
            onTap: _handleTap,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            backgroundColor: Colors.blue,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home),               label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.create),             label: ''), // 질문 플로우
              BottomNavigationBarItem(icon: Icon(Icons.directions_transit), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.person),             label: ''),
            ],
          ),
        ),
      ),
    );
  }
}