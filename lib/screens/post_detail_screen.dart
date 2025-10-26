// lib/screens/post_detail_screen.dart (최종 수정)

import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../services/auth_storage.dart';
import '../widgets/custom_app_bar.dart';
import 'post_create_screen.dart'; // 수정 화면 이동 시 필요

class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Map<String, dynamic>? _postData;
  List<dynamic> _comments = []; // 댓글 목록 저장
  final _commentController = TextEditingController(); // 댓글 입력 컨트롤러

  bool _isLoading = true;
  String? _error;
  
  int _currentImageIndex = 0; 
  int _likeCount = 0; // 좋아요 수
  bool _isLiked = false; // 현재 사용자의 좋아요 여부
  bool _listNeedsRefresh = false; // 목록 갱신 플래그

  int? _currentUserId; // 현재 로그인 유저 ID
  
  // 단일 정의
  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ✅ 댓글 시간 포맷 함수 (사용하지 않도록 수정)
  String _formatDateForComment(dynamic dateStr) {
    // 이 함수는 사용하지 않도록 수정하며, 필요하면 다른 곳에서 사용합니다.
    return ''; 
  }


  @override
  void initState() {
    super.initState();
    _fetchPostDetail();
    _fetchComments(); 
    _fetchCurrentUserId(); // 현재 사용자 ID 로드 함수 호출
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ✅ 현재 로그인된 사용자 ID를 서버에서 가져오는 함수
  Future<void> _fetchCurrentUserId() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) return; 

      final res = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode >= 200 && res.statusCode < 300 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _currentUserId = data['user_id'] ?? data['id']; 
        });
      }
    } catch (e) {
      // ID 로드 실패 시, _currentUserId는 null로 유지
    }
  }


  // ✅ 게시글 상세 정보 로드 (좋아요 수와 상태 통합)
  Future<void> _fetchPostDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthStorage.getToken();
      final uri = Uri.parse('$baseUrl/community/${widget.postId}');

      // 서버에서 좋아요 수와 is_liked를 반환하도록 수정이 필요합니다.
      final res = await http.get(
        uri,
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _postData = data;
          // ✅ 서버 응답의 좋아요 상태로 초기화 
          _likeCount = data['like_count'] ?? 0; 
          _isLiked = data['is_liked'] == true;         
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

  // ✅ 댓글 목록 로드 (유지)
  Future<void> _fetchComments() async {
    try {
      // ⚠️ 서버에서 user_name을 같이 조인하여 가져와야 합니다. (community.js 확인 필요)
      final uri = Uri.parse('$baseUrl/community/${widget.postId}/comments');
      final res = await http.get(uri);
      
      if (!mounted) return;
      
      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(() {
          _comments = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint('댓글 로드 오류: $e');
    }
  }

  // ✅ 좋아요 수 로드 함수는 PostDetail에 통합되었으므로, 불필요한 호출은 제거함
  Future<void> _fetchLikeCount() async {
    // 이 함수는 _fetchPostDetail에 통합되었습니다.
  }


  // ✅ 댓글 작성 기능 구현
  Future<void> _addComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      _showSnack('로그인이 필요합니다.');
      return;
    }

    _commentController.clear(); // 입력 즉시 비우기

    try {
      final uri = Uri.parse('$baseUrl/community/${widget.postId}/comments');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': commentText}),
      );

      if (!mounted) return;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        _showSnack('댓글 등록 성공');
        _fetchComments(); // 댓글 목록 갱신
      } else {
        _showSnack('댓글 등록 실패: ${res.statusCode}');
      }
    } catch (e) {
      _showSnack('네트워크 오류: $e');
    }
  }
  
  // ✅ 좋아요 토글 기능 구현 (하트 채우기/비우기)
  Future<void> _toggleLike() async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      _showSnack('로그인이 필요합니다.');
      return;
    }

    // UI에서 미리 상태를 변경하여 즉각적인 피드백 제공
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
      _listNeedsRefresh = true; // ✅ 목록 갱신 플래그 설정 (글 목록 반영을 위해 필수)
    });

    try {
      final uri = Uri.parse('$baseUrl/community/${widget.postId}/like');
      await http.post(uri, headers: { 'Authorization': 'Bearer $token' });
    } catch (e) {
      // 실패 시 UI 롤백
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
      _showSnack('네트워크 오류: $e');
    }
  }

  // ✅ 댓글 수정 기능 구현
  Future<void> _editComment(int commentId, String currentContent) async {
    final commentCtrl = TextEditingController(text: currentContent);
    final newContent = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('댓글 수정'),
        content: TextField(
          controller: commentCtrl,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, commentCtrl.text), child: const Text('저장')), // 컨트롤러 값 전달
        ],
      ),
    );
    if (newContent == null || newContent.trim().isEmpty || newContent.trim() == currentContent.trim()) return;
    
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) return _showSnack('로그인이 필요합니다.');

    try {
      final uri = Uri.parse('$baseUrl/community/comments/$commentId'); // 백엔드 라우트 가정
      final res = await http.put(
        uri,
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer $token' },
        body: jsonEncode({'content': newContent.trim()}),
      );

      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _showSnack('댓글이 수정되었습니다.');
        _fetchComments(); // 갱신
      } else if (res.statusCode == 403) {
        _showSnack('수정 권한이 없습니다.');
      } else {
        _showSnack('수정 실패: ${res.statusCode}');
      }
    } catch (e) {
      _showSnack('네트워크 오류: $e');
    }
  }
  
  // ✅ 댓글 삭제 기능 구현
  Future<void> _deleteComment(int commentId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) return _showSnack('로그인이 필요합니다.');

    try {
      final uri = Uri.parse('$baseUrl/community/comments/$commentId'); // 백엔드 라우트 가정
      final res = await http.delete(
        uri,
        headers: { 'Authorization': 'Bearer $token' },
      );

      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 204) {
        _showSnack('댓글이 삭제되었습니다.');
        _fetchComments(); // 갱신
      } else if (res.statusCode == 403) {
        _showSnack('삭제 권한이 없습니다.');
      } else {
        _showSnack('삭제 실패: ${res.statusCode}');
      }
    } catch (e) {
      _showSnack('네트워크 오류: $e');
    }
  }


  // 게시글 삭제 기능 구현
  Future<void> _deletePost() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;

    final token = await AuthStorage.getToken();
    try {
      final uri = Uri.parse('$baseUrl/community/${widget.postId}');
      final res = await http.delete(uri, headers: { 'Authorization': 'Bearer $token' });

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 204) {
        _showSnack('게시글이 삭제되었습니다.');
        Navigator.pop(context, true); // 커뮤니티 목록으로 돌아가 갱신
      } else if (res.statusCode == 403) {
        _showSnack('삭제 권한이 없습니다.');
      } else {
        _showSnack('삭제 실패: ${res.statusCode}');
      }
    } catch (e) {
      _showSnack('네트워크 오류: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    // 로딩 및 유저 ID 로드가 모두 완료될 때까지 대기
    if (_isLoading || _currentUserId == null) { 
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(appBar: AppBar(title: const Text('오류')), body: Center(child: Text(_error!)));
    }
    if (_postData == null) {
      return const Scaffold(body: Center(child: Text('게시글을 찾을 수 없습니다.')));
    }

    final String title = _postData!['post_title'] ?? '제목 없음';
    final String content = _postData!['content'] ?? '내용 없음';
    final String userName = _postData!['user_name'] ?? '익명';
    final String category = _postData!['category'] ?? '기타';
    
    final List<dynamic> mediaUrls = _postData!['media'] ?? [];
    final bool hasMedia = mediaUrls.isNotEmpty;

    // ✅ 소유권 결정: 게시글 작성자 ID와 현재 로그인 사용자 ID 비교
    final bool isOwner = _postData!['user_id'] == _currentUserId; 


    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        // ✅ 뒤로가기가 발생했고, 변경 사항이 있다면 부모 화면에 true를 반환
        // 이 true 값은 목록 화면(CommunityScreen)이 받아 새로고침하게 됩니다.
        if (didPop && _listNeedsRefresh) {
           Navigator.pop(context, true);
        }
      },
      child: Scaffold(
        appBar: const CustomAppBar(),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 다중 사진 슬라이더 섹션
              if (hasMedia) _buildImageSlider(mediaUrls),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 및 메타 정보
                    Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(userName, style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Text('| ${category}', style: const TextStyle(color: Colors.grey)),
                        const Spacer(),
                      ],
                    ),
                    const Divider(height: 30),

                    // 본문 내용
                    Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
                    const Divider(height: 30),

                    // 좋아요, 수정, 삭제 버튼 및 기능
                    _buildActionButtons(isOwner),
                    const Divider(height: 30),

                    // ✅ 댓글 섹션
                    _buildCommentSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 좋아요, 수정, 삭제 버튼 그룹 (소유권 플래그 받음)
  Widget _buildActionButtons(bool isOwner) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 좋아요 버튼
        TextButton.icon(
          onPressed: _toggleLike,
          icon: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border, // 좋아요 여부에 따라 아이콘 변경
            color: Colors.red
          ),
          // ✅ 좋아요 수 표시
          label: Text('좋아요 ${_likeCount}', style: TextStyle(color: Colors.red)),
        ),
        
        // 수정/삭제 버튼 (소유자에게만 표시)
        if (isOwner)
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  if (_postData != null) {
                    // PostCreateScreen으로 현재 데이터(_postData)를 전달하여 수정 모드로 이동
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PostCreateScreen(initialData: _postData)),
                    );
                    
                    // 수정 완료 후 복귀 시 상세 데이터 갱신
                    if (result == true) {
                      _fetchPostDetail();
                      _listNeedsRefresh = true; // ✅ 목록 갱신 플래그 설정
                    }
                  }
                },
                child: const Text('수정', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: _deletePost,
                child: const Text('삭제', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
      ],
    );
  }

  // ✅ 댓글 입력 및 목록 섹션 위젯
  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('댓글', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // 댓글 입력 필드
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: '댓글을 입력하세요.',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addComment(), // 엔터키로 등록 가능
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _addComment,
                child: const Text('등록'),
              ),
            ],
          ),
        ),

        // ✅ 댓글 목록: 삼항 연산자로 안전하게 분기 
        _comments.isEmpty
          ? ListTile(title: const Text('댓글이 없습니다.'), subtitle: Text('첫 댓글을 작성해보세요.'))
          : ListView.builder(
            shrinkWrap: true, // 부모 SingleChildScrollView에 맞춤
            physics: const NeverScrollableScrollPhysics(), // 스크롤 막기
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              // 댓글 작성자 ID와 현재 사용자 ID 비교
              final bool isCommentOwner = comment['user_id'] == _currentUserId;
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person, size: 20)),
                // ✅ 수정: user_name 필드를 사용 (서버에서 가져왔다고 가정)
                title: Text(comment['user_name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(comment['content']),
                trailing: isCommentOwner 
                    ? PopupMenuButton<String>( // ✅ 댓글 소유자에게만 팝업 메뉴 표시
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editComment(comment['comment_id'], comment['content']);
                          } else if (value == 'delete') {
                            _deleteComment(comment['comment_id']);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('수정')),
                          const PopupMenuItem(value: 'delete', child: Text('삭제')),
                        ],
                        icon: const Icon(Icons.more_vert, size: 18),
                      )
                    : null, // ✅ 소유자가 아니면 아무것도 표시하지 않음 (시간 제거)
              );
            },
          ),
      ],
    );
  }


  // 이미지 슬라이더 위젯
  Widget _buildImageSlider(List<dynamic> mediaUrls) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 300, 
          child: PageView.builder(
            itemCount: mediaUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final String imageUrl = mediaUrls[index]['media_url'] ?? mediaUrls[index].toString(); 
              final fullUrl = imageUrl.startsWith('http') ? imageUrl : '$baseUrl/$imageUrl';
              
              return Image.network(
                fullUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey)),
              );
            },
          ),
        ),
        // 인디케이터 (현재 페이지 위치 표시)
        Positioned(
          bottom: 10,
          child: Row(
            children: List.generate(mediaUrls.length, (index) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index 
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}