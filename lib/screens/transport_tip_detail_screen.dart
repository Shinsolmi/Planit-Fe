// lib/screens/transport_tip_detail_screen.dart (수정)

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
  bool _loadingSaveStatus = true;
  
  // tip 데이터에서 필요한 정보 추출
  int get _tipId => (widget.tip['id'] ?? 0) as int; // 팁 ID
  String get _tipContent => (widget.tip['content'] ?? '').toString();
  String get _transportType => (widget.tip['transport_type'] ?? '').toString();
  String get _title => (widget.tip['title'] ?? '교통 팁').toString(); // 제목 추출

  // mediaList 추출 (tip['media']가 List인지 확인)
  // ⚠️ 서버에서 이 미디어 리스트를 tip 객체에 포함하여 보내줘야 합니다.
  List<dynamic> get _mediaList => (widget.tip['media'] is List) ? widget.tip['media'] : [];


  @override
  void initState() {
    super.initState();
    _checkSavedStatus(); // 1. 초기 저장 상태 확인
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ✅ 팁의 저장 상태를 서버에서 확인하는 함수 (기존 유지)
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

  // ✅ 저장/취소 토글 함수 (기존 유지)
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
  
  // ✅ 다중 미디어 목록을 순회하며 위젯 리스트를 빌드하는 함수 (수정)
  List<Widget> _buildMediaList(BuildContext context, List<dynamic> mediaList) {
    if (mediaList.isEmpty) return [];

    return mediaList.expand<Widget>((media) {
      final mediaUrl = media['media_url'] as String? ?? '';
      final mediaType = media['media_type'] as String? ?? '';
      final caption = media['caption'] as String? ?? '';
      
      if (mediaUrl.isEmpty) return [];
      
      Widget currentMediaWidget;

      // 이미지 처리 로직
      if (mediaType == 'image') {
        // ⭐️ 이미지 URL이 완전한 형태가 아닐 경우 baseUrl과 조합
        final imgUrl = mediaUrl.startsWith('http') ? mediaUrl : '$baseUrl/$mediaUrl';
        
        currentMediaWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            imgUrl,
            // ⭐️ 이미지 크기를 화면 너비에 맞게 조정 (왼쪽 정렬 효과)
            width: MediaQuery.of(context).size.width - 48, 
            fit: BoxFit.fitWidth, 
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) => 
              Container( // 이미지 로드 실패 시 아이콘을 담을 컨테이너
                width: MediaQuery.of(context).size.width - 48,
                height: 150, // 임시 높이
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
              children: [
                // 1. 제목 표시
                Text(
                  _title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                // ✅ 저장 버튼 위젯
                if (_loadingSaveStatus)
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  IconButton(
                    icon: Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: _isSaved ? Colors.blue : Colors.grey,
                      size: 28,
                    ),
                    onPressed: _toggleSave,
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. 본문 내용 (content) - 단일 Text에서 목록 위젯으로 대체
            ..._buildContentList(_tipContent),

            // 3. 미디어 위젯 목록 (동영상/이미지) - 왼쪽 정렬
            if (_mediaList.isNotEmpty) const SizedBox(height: 20),
            ..._buildMediaList(context, _mediaList), 

            // 4. 상세 정보 (details)
            if (details.isNotEmpty) ...[
              const SizedBox(height: 16), // 미디어와 상세 정보 텍스트 간의 간격
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