// lib/screens/transport_tip_detail_screen.dart (최종 수정: 오버플로우 해결 및 저장 상태 로직 복구)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; 
import '../env.dart';
import '../services/auth_storage.dart';
import '../widgets/custom_app_bar.dart';

class TransportTipDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tip; // tip 객체를 받습니다.

  const TransportTipDetailScreen({
    super.key,
    required this.tip,
  });

  @override
  State<TransportTipDetailScreen> createState() => _TransportTipDetailScreenState();
}

class _TransportTipDetailScreenState extends State<TransportTipDetailScreen> {
  // 팁이 이미 저장되었는지 확인하는 상태
  bool _isSaved = false; 
  // ⚠️ _loadingSaveStatus를 true로 복구하여, 화면 진입 시 서버에서 상태를 다시 불러오도록 함 (저장 상태 유지 문제 해결의 핵심)
  bool _loadingSaveStatus = true; 
  
  // tip 데이터에서 필요한 정보 추출
  int get _tipId => (widget.tip['id'] ?? 0) as int; 
  String get _tipContent => (widget.tip['content'] ?? '').toString();
  String get _title => (widget.tip['title'] ?? '교통 팁').toString(); 
  String get _details => (widget.tip['details'] ?? '').toString(); 

  // mediaList 추출
  List<dynamic> get _mediaList => (widget.tip['media'] is List) ? widget.tip['media'] : [];


  @override
  void initState() {
    super.initState();
    _checkSavedStatus(); // 1. 초기 저장 상태 확인 (서버에서 가져옴)
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ✅ 팁의 저장 상태를 서버에서 확인하는 함수 (복구/유지)
  Future<void> _checkSavedStatus() async {
    final token = await AuthStorage.getToken();
    if (token == null || _tipId == 0) {
      if (mounted) setState(() => _loadingSaveStatus = false);
      return;
    }
    
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/users/me/saved-tips'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final List savedTips = jsonDecode(res.body);
        final bool isCurrentlySaved = savedTips.any((tip) => tip['id'] == _tipId);
        if (mounted) {
          setState(() {
            _isSaved = isCurrentlySaved;
            _loadingSaveStatus = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingSaveStatus = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingSaveStatus = false);
    }
  }

  // ✅ 저장/취소 토글 함수 (복구/유지)
  Future<void> _toggleSave() async { 
    final token = await AuthStorage.getToken();
    if (token == null) {
      _showSnack('로그인이 필요합니다.');
      return;
    }
    
    // UI에서 미리 상태 변경 (즉각적인 피드백)
    setState(() => _isSaved = !_isSaved);
    _showSnack(_isSaved ? '팁을 저장했습니다.' : '저장을 취소했습니다.');

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/users/me/saved-tips'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'tip_id': _tipId}), // 팁 ID 전달
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        // 서버 실패 시 UI 롤백
        if (mounted) setState(() => _isSaved = !_isSaved);
        _showSnack('저장/취소 처리 실패');
      }
      
    } catch (e) {
      // 네트워크 오류 시 UI 롤백
      if (mounted) setState(() => _isSaved = !_isSaved);
      _showSnack('네트워크 오류');
    }
  }
  
  // 외부 URL 연결 기능 (기존 유지)
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  // ✅ 다중 미디어 목록을 순회하며 위젯 리스트를 빌드하는 함수 (이미지 표시)
  List<Widget> _buildMediaList(BuildContext context, List<dynamic> mediaList) {
    if (mediaList.isEmpty) return [];
    
    // 현재 패딩 24.0 * 2 = 48.0 이므로, 양쪽 패딩을 제외한 너비를 계산합니다.
    final double maxMediaWidth = MediaQuery.of(context).size.width - 48.0; 

    return mediaList.expand<Widget>((media) {
      final mediaUrl = media['media_url'] as String? ?? '';
      final mediaType = media['media_type'] as String? ?? '';
      final caption = media['caption'] as String? ?? '';
      
      if (mediaUrl.isEmpty) return [];
      
      Widget currentMediaWidget;

      // 이미지 처리 로직
      if (mediaType == 'image') {
        final imgUrl = mediaUrl.startsWith('http') ? mediaUrl : '$baseUrl/$mediaUrl';
        
        currentMediaWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            imgUrl,
            width: maxMediaWidth, 
            fit: BoxFit.fitWidth, 
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: maxMediaWidth,
                height: 150,
                color: Colors.grey[100],
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
            errorBuilder: (context, error, stackTrace) => 
              Container( // 이미지 로드 실패 시 아이콘을 담을 컨테이너
                width: maxMediaWidth,
                height: 150, 
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
              ),
          ),
        );
      } 
      // 동영상 (video) 처리 로직: 외부 연결 (기존 유지)
      else if (mediaType == 'video') {
         currentMediaWidget = InkWell(
          onTap: () => _launchUrl(mediaUrl),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.red, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.videocam, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '동영상 링크 보기 (클릭)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mediaUrl,
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis, 
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new, color: Colors.red),
              ],
            ),
          ),
        );
      } else {
        return []; // 지원하지 않는 미디어 타입은 건너뜀
      }

      // 위젯과 캡션을 함께 반환
      return [
        const SizedBox(height: 16), // 미디어 간 간격
        currentMediaWidget,
        if (caption.isNotEmpty) Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 4.0),
          child: Text(
            caption, 
            style: const TextStyle(
              color: Colors.black, 
              fontStyle: FontStyle.normal,
              fontSize: 14,
            ),
          ),
        ),
      ];
    }).toList();
  }

  // 새로운 함수: content를 줄바꿈하고 목록 위젯으로 변환 (기존 유지)
  List<Widget> _buildContentList(String content) {
    if (content.isEmpty) return [const Text('내용 없음')];

    // 줄바꿈 문자로 문자열을 분리하고, 공백 줄을 제거
    final List<String> lines = content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return lines.map((line) {
      // 각 줄을 블릿 포인트와 함께 Row로 표시
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(fontSize: 16, height: 1.5)), // 블릿 포인트
            Expanded(
              child: Text(
                line,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    final String details = widget.tip['details'] ?? ''; 
    
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start, // ⭐️ Row 정렬 시작점 지정
              children: [
                // 1. 제목 표시 (수정: Expanded로 감싸서 오버플로우 방지)
                Expanded( // ⭐️ Expanded 추가
                  child: Text(
                    _title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    maxLines: 2, // 제목 최대 2줄
                    overflow: TextOverflow.ellipsis, // 넘치면 ...으로 표시
                  ),
                ),
                // 2. 저장 버튼 위젯 (오른쪽 상단 고정)
                // IconButton 자체는 Row 내에서 자체 공간을 확보합니다.
                if (_loadingSaveStatus)
                  const SizedBox(width: 28, height: 28, child: Center(child: CircularProgressIndicator(strokeWidth: 2))) // 공간 확보
                else
                  IconButton(
                    icon: Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: _isSaved ? Colors.blue : Colors.grey,
                      size: 28,
                    ),
                    onPressed: _toggleSave,
                    padding: EdgeInsets.zero, 
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28), // 버튼 최소 크기 지정
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. 본문 내용 (content)
            ..._buildContentList(_tipContent),

            // 3. 미디어 위젯 목록 (동영상/이미지) - 핵심 수정 부분
            if (_mediaList.isNotEmpty) const SizedBox(height: 20),
            ..._buildMediaList(context, _mediaList), 

            // 4. 상세 정보 (details)
            if (details.isNotEmpty) ...[
              const SizedBox(height: 16), 
              Text(details, style: const TextStyle(fontSize: 15)),
            ],

            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('목록으로 돌아가기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}