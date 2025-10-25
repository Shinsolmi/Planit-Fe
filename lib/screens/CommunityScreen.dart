// lib/screens/community_screen.dart (최종 수정)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../widgets/custom_app_bar.dart';
import 'post_detail_screen.dart'; 
// import 'post_create_screen.dart'; // 글 작성 화면 필요 시 추가

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // DB 스키마에 맞춰 카테고리 확장: '맛집', '행사', '사건', '핫플', '기타'
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
    _fetchPosts(_selectedCategory);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ 게시글 목록을 서버에서 불러오는 함수 (searchQuery 매개변수 추가)
  Future<void> _fetchPosts(String? category, {String? searchQuery}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isAll = category == '전체' || category == null;
      
      final Map<String, dynamic> queryParams = {};
      if (!isAll) {
        queryParams['category'] = category;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['query'] = searchQuery;
      }
      
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
    _fetchPosts(_selectedCategory, searchQuery: value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
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
          
          // 2. 카테고리 칩 목록
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
                        ? Center(child: Text('${_selectedCategory ?? "전체"} 카테고리 및 검색 결과가 없습니다.'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _posts.length,
                            itemBuilder: (context, index) {
                              final post = _posts[index];
                              
                              // ✅ 작성자 이름이 없으면 ID를 사용하고, 좋아요 수를 함께 표시
                              final String userName = post['user_name'] ?? post['user_id'].toString(); 
                              final int likeCount = post['like_count'] ?? 0;
                              final String createdAt = _formatDateForPostList(post['created_at']); // ✅ 시간 포맷

                              return ListTile(
                                leading: const Icon(Icons.article), 
                                title: Text(post['post_title'] ?? '제목 없음', maxLines: 1, overflow: TextOverflow.ellipsis),
                                // ✅ 작성자 이름과 좋아요 수, 시간 표시
                                subtitle: Text(
                                  '작성자: $userName · ${createdAt} · 좋아요: $likeCount', 
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                                trailing: Text(post['category'] ?? '기타', style: TextStyle(color: Colors.blue.shade600)),
                                onTap: () async {
                                  // 상세 페이지로 이동하며 갱신 신호를 기다림 (좋아요 반영)
                                  final bool? needsRefresh = await Navigator.push<bool>(
                                    context, 
                                    MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post['post_id'])),
                                  );
                                  if (needsRefresh == true) {
                                    _fetchPosts(_selectedCategory, searchQuery: _searchController.text);
                                  }
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 글 작성 화면으로 이동
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}