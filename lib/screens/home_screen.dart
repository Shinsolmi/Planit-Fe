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
import 'CommunityScreen.dart';
import 'post_detail_screen.dart'; // PostDetailScreen import 추가

// ✅ StatefulWidget으로 변경
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _summaryData; // ✅ Map 타입 유지
  bool _isLoadingSummary = true;
  
  // ✅ 검색 컨트롤러 추가
  final TextEditingController _searchController = TextEditingController();

  // ✅ 글쓴 시간 포맷 함수 (YYYY.MM.DD 형식으로 변환)
  String _formatDateForPostList(dynamic dateStr) {
    if (dateStr == null) return '';
    final s = dateStr.toString();
    try {
        final d = DateTime.parse(s).toLocal();
        // 홈 화면에서는 간략하게 YYYY.MM.DD 형식만 표시하도록 조정
        return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}'; 
    } catch (_) {
        return s.length > 10 ? s.substring(0, 10) : s; // Fallback
    }
  }


  @override
  void initState() {
    super.initState();
    _loadSummaryData(); // 1. 초기 데이터 로드
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ 커뮤니티 요약 데이터 로드 함수 (로딩 인디케이터 문제 해결)
  Future<void> _loadSummaryData() async {
    if (!mounted) return;
    setState(() => _isLoadingSummary = true);
    try {
      final url = Uri.parse('$baseUrl/main/summary');
      final res = await http.get(url);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (!mounted) return;
        setState(() {
          // ⭐️ 안전한 데이터 저장: Map 형태로 들어오지 않거나 오류가 있어도 기본값으로 처리 후 로딩 종료
          if (data is Map<String, dynamic>) {
            _summaryData = data; 
          } else {
            _summaryData = {'popularPosts': []};
          }
          _isLoadingSummary = false;
        });
      } else {
        if (mounted) setState(() {
          _isLoadingSummary = false;
          _summaryData = {'popularPosts': []};
          debugPrint('Summary load failed: ${res.statusCode}');
        });
      }
    } catch (e) {
      if (mounted) setState(() {
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

  // ✅ 상세 페이지 이동 후 목록 갱신 로직 (좋아요 반영 핵심)
  Future<void> _navigateToPostDetail(int postId) async {
    // 상세 페이지로 이동하며, 반환되는 결과(true/false)를 기다립니다.
    final bool? needsRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)),
    );

    // ✅ PostDetailScreen에서 true(상태 변경됨)를 반환했을 경우 목록 새로고침
    if (needsRefresh == true) {
      _loadSummaryData(); // ⭐️ 목록 데이터를 다시 불러와서 좋아요 수를 갱신합니다.
    }
  }


  // ✅ 커뮤니티 요약 위젯 빌드 (작성자 이름 및 시간 표시 로직 통합)
  Widget _buildCommunitySummary() {
    // ⭐️ 안전한 데이터 추출
    final List<dynamic> posts = (_summaryData is Map && _summaryData!.containsKey('popularPosts')) 
        ? _summaryData!['popularPosts'] as List<dynamic>
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '기억하고 싶은 여행이 있으신가요? ✈️', 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text('사진과 함께 후기를 저장해보세요.', style: TextStyle(color: Colors.grey[700])),
        const SizedBox(height: 16),

        _isLoadingSummary
            ? const Center(child: CircularProgressIndicator()) // ⬅️ 로딩 인디케이터 표시
            : posts.isEmpty
                ? Center(child: Text('인기 게시글이 없습니다.'))
                : Column(
                    children: posts.take(5).map((post) {
                      final postId = post['post_id'] as int?;
                      final title = post['post_title'] ?? '제목 없음';
                      final likes = post['like_count']?.toString() ?? '0'; 
                      final createdAt = post['created_at'] ?? ''; 
                      final userName = post['user_name'] ?? '익명'; 
                      final mediaUrl = post['media_url']; // ✅ 이미지 URL 추출 (서버에서 가져와야 함)

                      // ✅ 게시글 썸네일 위젯 생성: 이미지가 있을 때만 SizedBox에 Image.network를 넣고, 없을 때는 null 반환
                      final Widget? leadingWidget = (mediaUrl != null && mediaUrl.isNotEmpty)
                            ? SizedBox(
                                width: 60, 
                                height: 60, 
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    // ⭐️ 최종 URL 경로 조합: baseUrl + mediaUrl
                                    '$baseUrl/$mediaUrl', 
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                                  ),
                                ),
                              )
                            : null; // ✅ 이미지가 없을 때는 null을 반환하여 아무것도 표시하지 않음 (기본 아이콘 제거)
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: leadingWidget, // ✅ leading에 이미지 또는 null 배치 (왼쪽 정렬)
                          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Row(
                            children: [
                              // ✅ 작성자 이름 표시
                              Text('작성자: $userName', style: TextStyle(color: Colors.blue.shade600, fontSize: 12)),
                              const SizedBox(width: 8),
                              // ✅ 글쓴 시간 추가
                              Text(_formatDateForPostList(createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              const SizedBox(width: 8),
                              Icon(Icons.favorite, size: 14, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(likes, style: TextStyle(color: Colors.red, fontSize: 12)), // ✅ 좋아요 수 표시
                            ],
                          ),
                          trailing: post['category'] != null ? Text(post['category'], style: TextStyle(color: Colors.blue.shade600)) : null,
                          onTap: () {
                            if (postId != null) {
                               _navigateToPostDetail(postId); // ✅ 상세 이동 및 갱신 로직
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
        
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: () async {
               final bool? needsRefresh = await Navigator.push<bool>( // ✅ 갱신 신호 받기
                context,
                MaterialPageRoute(builder: (_) => const CommunityScreen()), // 커뮤니티 메인 이동
              );
              // 커뮤니티 메인에서 돌아올 때 갱신 신호를 받으면 홈 화면 목록 갱신
              if (needsRefresh == true) {
                _loadSummaryData(); 
              }
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


  // ✅ _buildActionButton 함수 (재사용)
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
            controller: _searchController, // 컨트롤러 연결
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
          
          const SizedBox(height: 8), 

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
          
          const SizedBox(height: 24),
          const Divider(height: 40),

          // ✅ 5. 커뮤니티 요약 섹션
          _buildCommunitySummary(),

          const SizedBox(height: 24), // 최종 하단 간격
        ],
      ),
    );
  }
}