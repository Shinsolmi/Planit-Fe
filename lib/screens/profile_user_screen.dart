// lib/screens/profile_user_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/custom_app_bar.dart';
import '../services/auth_storage.dart';
import '../env.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'my_schedules_screen.dart';
import 'schedule_detail_screen.dart'; // ✅ ScheduleDetailScreen import 추가

class ProfileUserScreen extends StatefulWidget {
  const ProfileUserScreen({super.key});

  @override
  State<ProfileUserScreen> createState() => _ProfileUserScreenState();
}

class _ProfileUserScreenState extends State<ProfileUserScreen> {
  bool _loading = true;
  bool _loggedIn = false;
  Map<String, dynamic>? _me;

  @override
  void initState() {
    super.initState();
    _refresh(); // 로그인 상태 + 프로필 로드
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
    });

    final logged = await AuthStorage.isLoggedIn();
    if (!mounted) return;

    if (!logged) {
      setState(() {
        _loggedIn = false;
        _me = null;
        _loading = false;
      });
      return;
    }

    // 로그인 상태면 프로필 호출
    try {
      final token = await AuthStorage.getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/users/me'), // 백엔드 스펙에 맞게 필요시 수정
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        setState(() {
          _loggedIn = true;
          _me = (data is Map<String, dynamic>) ? data : <String, dynamic>{};
          _loading = false;
        });
      } else {
        // 프로필 실패 시에도 로그인은 true로 간주하고 메시지 출력
        setState(() {
          _loggedIn = true;
          _me = <String, dynamic>{};
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 로드 실패: ${res.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loggedIn = true;
        _me = <String, dynamic>{};
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

Future<void> _logout() async {
  // 1) 확인 다이얼로그: 반드시 로컬 컨텍스트 사용!
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('로그아웃'),
      content: const Text('정말 로그아웃할까요?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false), // ← dialogCtx 사용
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogCtx, true), // ← dialogCtx 사용
          child: const Text('로그아웃'),
        ),
      ],
    ),
  ) ?? false;

  if (!ok || !mounted) return;

  // 2) 토큰/세션 정리
  try {
    await AuthStorage.logout();
  } catch (e, st) {
    debugPrint('Logout error: $e\n$st');
  }
  if (!mounted) return;

  // 3) 화면을 게스트 상태로 갱신
  setState(() {
    _loggedIn = false;
    _me = null;
    _loading = false;
  });

  // 4) 스낵바는 안전하게 (없으면 조용히 패스)
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(const SnackBar(content: Text('로그아웃되었습니다.')));
}

  // ✅ 추가: 예정된 일정 중 가장 최근 일정을 가져와서 상세 화면으로 이동
  Future<void> _navigateToLatestSchedule() async {
    // 1) 로딩 상태 표시
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('가장 가까운 예정된 일정을 불러오는 중입니다...'),
      duration: Duration(seconds: 2),
    ));

    // 2) 백엔드 API 호출
    try {
      final token = await AuthStorage.getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/schedules/me'),
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List<dynamic> schedules = jsonDecode(res.body);
        if (schedules.isNotEmpty) {
          final latestSchedule = schedules[0]; // 백엔드에서 정렬되어 온 첫 번째 일정
          final scheduleId = latestSchedule['schedule_id'];
          
          // 3) 일정 상세 화면으로 이동
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScheduleDetailScreen(scheduleId: scheduleId),
            ),
          );
        } else {
          // 일정이 없을 경우 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('예정된 일정이 없습니다.'),
            duration: Duration(seconds: 2),
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('일정 로드 실패: ${res.statusCode}'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('네트워크 오류: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(), // 로고=홈 탭 전환(이미 탭 편입 구조)
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loggedIn
              ? _buildLoggedIn()
              : _buildGuest(),
    );
  }

Widget _menuItem(IconData icon, String title, {VoidCallback? onTap}) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    visualDensity: VisualDensity.compact,
  );
}

  // 로그인 후 UI
 Widget _buildLoggedIn() {
  final name = (_me?['user_name'] ?? _me?['name'] ?? '사용자').toString();
  final email = (_me?['email'] ?? '-').toString();

  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // 프로필 + 이름/이메일 (프로필 밑으로 이동)
      Center(
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),

      const SizedBox(height: 24),
      const Divider(),

      // 메뉴 리스트
      _menuItem(Icons.event_available, '예정된 일정', onTap: _navigateToLatestSchedule),
      _menuItem(
        Icons.history,
        '지난 일정 관리',
        onTap: () {
          // TODO: 내 일정 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MySchedulesScreen(),
            ),
          );
        },
      ),
      _menuItem(Icons.train, '저장한 대중교통 팁', onTap: () { /* TODO */ }),
      _menuItem(Icons.rate_review, '작성한 글', onTap: () { /* TODO */ }),

      const SizedBox(height: 16),

      // 로그아웃 버튼 (작성한 후기 밑으로 이동)
      OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout),
        label: const Text('로그아웃'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    ],
  );
}

  // 게스트 UI
  Widget _buildGuest() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('로그인이 필요합니다', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()))
                    .then((_) => _refresh()), // 돌아오면 상태 갱신
                child: const Text('로그인'),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()))
                    .then((_) => _refresh()),
                child: const Text('회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}