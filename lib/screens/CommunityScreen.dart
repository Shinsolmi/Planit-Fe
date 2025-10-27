// lib/screens/community_screen.dart (최종 수정)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../widgets/custom_app_bar.dart';
import 'post_detail_screen.dart'; 
import 'post_create_screen.dart'; // 글 작성 화면 필요 시 import

class CommunityScreen extends StatefulWidget {
  // ✅ 필터링을 위한 userId 파라미터 추가
  final int? filterUserId; 
  
  const CommunityScreen({super.key, this.filterUserId}); // ✅ 생성자에 추가

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<String> _categories = ['전체', '맛집', '행사', '사건', '핫플', '기타'];
  String? _selectedCategory = '전체';
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String? _error;
  
  final TextEditingController _searchController = TextEditingController();

  // ✅ 글쓴 시간 포맷 함수 (YYYY-MM-DD 형식으로 변환)
  String _formatDateForPostList(dynamic dateStr) {
    if (dateStr == null) return '';
    final s = dateStr.toString();
    try {
        final d = DateTime.parse(s).toLocal();
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'; 
    } catch (_) {
        return s.length > 10 ? s.substring(0, 10) : s; // Fallback
    }
  }

  @override
  void initState() {
    super.initState();
    // ⭐️ initState에서 필터를 적용하여 로드
    _fetchPosts(_selectedCategory, filterUserId: widget.filterUserId); 
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ _fetchPosts 함수 수정 (filterUserId 수용)
  Future<void> _fetchPosts(String? category, {String? searchQuery, int? filterUserId}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isAll = category == '전체' || category == null;
      
      // 쿼리 파라미터 구성
      final Map<String, dynamic> queryParams = {};
      if (!isAll) {
        queryParams['category'] = category;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['query'] = searchQuery;
      }
      
      // ✅ 필터링된 user_id 추가 (핵심: 마이페이지에서 넘어온 ID)
      if (filterUserId != null) {
          queryParams['user_id'] = filterUserId.toString(); // 서버에 user_id를 쿼리 파라미터로 전달
      }
      
      // /community API는 제목 검색 필터링을 지원해야 합니다.
      final uri = Uri.parse('$baseUrl/community').replace(queryParameters: queryParams.isNotEmpty ? queryParams.map((k, v) => MapEntry(k, v.toString())) : null);

      final res = await http.get(uri);

      if (!mounted) return;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List<dynamic> fetchedPosts = jsonDecode(res.body);
        setState(() {
          _posts = fetchedPosts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '게시글 로드 실패: ${res.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '네트워크 오류: $e';
        _isLoading = false;
      });
    }
  }

  void _performSearch(String value) {
    // ⭐️ 검색 시에도 filterUserId 유지
    _fetchPosts(_selectedCategory, searchQuery: value, filterUserId: widget.filterUserId);
  }

  @override
  Widget build(BuildContext context) {
    // 마이페이지에서 왔을 경우 AppBar 제목 변경
    final String appBarTitle = widget.filterUserId != null ? '내가 작성한 글' : '커뮤니티';

    return Scaffold(
      appBar: CustomAppBar(title: appBarTitle), // AppBar에 제목 표시
      body: Column(
        children: [
          // 1. 검색 바
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '게시글 제목을 검색하세요.',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              onSubmitted: _performSearch, // 엔터 입력 시 검색 실행
            ),
          ),
          
          // 2. 카테고리 칩 목록 (마이페이지 필터 시 카테고리 필터링은 생략)
          if (widget.filterUserId == null) // 마이페이지 필터가 없을 때만 카테고리 표시
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Wrap(
                spacing: 8,
                children: _categories.map((cat) => ChoiceChip(
                  label: Text(cat),
                  selected: _selectedCategory == cat,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = cat;
                      _fetchPosts(cat, searchQuery: _searchController.text);
                    });
                  },
                  selectedColor: Colors.blue,
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(
                    color: _selectedCategory == cat ? Colors.white : Colors.black,
                  ),
                )).toList(),
              ),
            ),
          const Divider(height: 1),
          
          // 3. 게시글 목록 (ListView)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _posts.isEmpty && !_isLoading 
                        ? Center(child: Text(widget.filterUserId != null ? '작성하신 글이 없습니다.' : '게시글이 없습니다.'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _posts.length,
                            itemBuilder: (context, index) {
                              final post = _posts[index];
                              
                              // 작성자 이름이 없으면 '익명'을 사용하고, 좋아요 수를 함께 표시
                              final String userName = post['user_name'] ?? '익명'; 
                              final int likeCount = post['like_count'] ?? 0;
                              final String createdAt = _formatDateForPostList(post['created_at']); // ✅ 시간 포맷
                              final String? mediaUrl = post['media_url']; // ✅ 이미지 URL 추출

                              // ✅ 게시글 썸네일 위젯 생성
                              final Widget leadingWidget = (mediaUrl != null && mediaUrl.isNotEmpty)
                                    ? SizedBox(
                                        width: 60, 
                                        height: 60, 
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8.0),
                                          child: Image.network(
                                            '$baseUrl/$mediaUrl', // 서버 URL과 이미지 경로 조합
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                                          ),
                                        ),
                                      )
                                    : const SizedBox(width: 24, height: 24); // ✅ 이미지가 없으면 빈 공간만 남기고 아이콘 제거

                              return ListTile(
                                leading: leadingWidget, // ✅ leading에 이미지 또는 빈 공간 배치
                                title: Text(post['post_title'] ?? '제목 없음', maxLines: 1, overflow: TextOverflow.ellipsis),
                                // ✅ 수정: 작성자 이름과 시간, 좋아요 수 표시
                                subtitle: Text(
                                  '작성자: $userName · $createdAt · 좋아요: $likeCount', 
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                                trailing: Text(post['category'] ?? '기타', style: TextStyle(color: Colors.blue.shade600)),
                                onTap: () async {
                                  // 상세 페이지로 이동하며 갱신 신호를 기다림 (좋아요 반영)
                                  final bool? needsRefresh = await Navigator.push<bool>(
                                    context, 
                                    MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post['post_id'])),
                                  );
                                  // PostDetailScreen에서 true를 반환하면 목록 갱신
                                  if (needsRefresh == true) {
                                    _fetchPosts(_selectedCategory, searchQuery: _searchController.text, filterUserId: widget.filterUserId);
                                  }
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 글 작성 화면으로 이동
          final bool? needsRefresh = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const PostCreateScreen()),
          );
          // 글 작성이 완료된 후 (true 반환) 목록을 갱신
          if (needsRefresh == true) {
            _fetchPosts(_selectedCategory, searchQuery: _searchController.text, filterUserId: widget.filterUserId);
          }
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}