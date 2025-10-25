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

// ✅ StatefulWidget으로 변경 (데이터 로드를 위해)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _summaryData;
  bool _isLoadingSummary = true;

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
  }

  // ✅ 커뮤니티 요약 데이터 로드 함수
  Future<void> _loadSummaryData() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/main/summary'));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!mounted) return;
        setState(() {
          _summaryData = jsonDecode(res.body) as Map<String, dynamic>;
          _isLoadingSummary = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoadingSummary = false;
          _summaryData = {'popularPosts': []}; 
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSummary = false;
        _summaryData = {'popularPosts': []};
        debugPrint('Summary network error: $e');
      });
    }
  }


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

  // ✅ 커뮤니티 요약 위젯 빌드
  Widget _buildCommunitySummary() {
    final List<dynamic> posts = _summaryData?['popularPosts'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '행사/핫플 정보를 확인하고 싶으신가요?	✈️',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text('여러정보와 후기를 확인해보세요.', style: TextStyle(color: Colors.grey[700])),
        const SizedBox(height: 16),

        _isLoadingSummary
            ? const Center(child: CircularProgressIndicator())
            : posts.isEmpty
                ? Center(child: Text('인기 게시글이 없습니다.'))
                : Column(
                    children: posts.take(5).map((post) {
                      final title = post['post_title'] ?? '제목 없음';
                      final likes = post['like_count']?.toString() ?? '0';
                      final createdAt = post['created_at'] ?? ''; 
                      final userName = post['user_name'] ?? '익명';
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Row(
                            children: [
                              Text(userName, style: TextStyle(color: Colors.blue.shade600, fontSize: 12)),
                              const SizedBox(width: 8),
                              Text(createdAt, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              const SizedBox(width: 8),
                              Icon(Icons.favorite, size: 14, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(likes, style: TextStyle(color: Colors.red, fontSize: 12)),
                            ],
                          ),
                          trailing: Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200], 
                            child: const Center(
                              child: Icon(Icons.image_outlined, color: Colors.grey),
                            ),
                          ),
                          onTap: () {
                            // TODO: 상세 커뮤니티 게시글 화면으로 이동
                          },
                        ),
                      );
                    }).toList(),
                  ),
        
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: () {
              // TODO: 커뮤니티 메인 화면으로 이동
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              side: BorderSide(color: Colors.blueGrey.shade300),
            ),
            child: Text('커뮤니티 보러가기', style: TextStyle(color: Colors.blueGrey.shade700)),
          ),
        ),
      ],
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
          // 1. 검색창
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
          
          const SizedBox(height: 8), // 검색창과 문구 사이 간격 (원래대로)

          // 2. 여행 시작 문구
          Text(
            '여행을 시작해 볼까요?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // 3. '여행 만들기' 버튼
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
          
          // 4. '내 일정' 버튼
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
          
          // ✅ 5. 커뮤니티 요약 섹션 (내 일정 버튼 아래로 이동)
          const SizedBox(height: 24), // 버튼과 섹션 사이 간격
          const Divider(height: 40), 
          _buildCommunitySummary(),

          const SizedBox(height: 24), // 최종 하단 간격
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