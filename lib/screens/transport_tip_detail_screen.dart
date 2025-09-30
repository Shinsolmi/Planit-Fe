// lib/screens/transport_tip_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../widgets/custom_app_bar.dart';
import '../env.dart'; 

class TransportTipDetailScreen extends StatelessWidget {
  final Map<String, dynamic> tip;

  const TransportTipDetailScreen({
    super.key,
    required this.tip,
  });

  // 외부 URL 연결 기능
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  // 다중 미디어 목록을 순회하며 위젯 리스트를 빌드하는 함수
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
        final imgUrl = mediaUrl.startsWith('http') ? mediaUrl : '$baseUrl/$mediaUrl';
        
        currentMediaWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            imgUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) => 
              const Icon(Icons.broken_image, size: 100),
          ),
        );
      } 
      // 동영상 (video) 처리 로직: 외부 연결
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
              // ✅ 스타일 수정: 검은색, 일반 글씨체(이탤릭체 제거)
              color: Colors.black, 
              fontStyle: FontStyle.normal,
              fontSize: 14,
            ),
          ),
        ),
      ];
    }).toList();
  }

  // ✅ 새로운 함수: content를 줄바꿈하고 목록 위젯으로 변환
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
    final String title = tip['title'] ?? '교통 팁';
    final String content = tip['content'] ?? '내용 없음';
    final String details = tip['details'] ?? ''; 
    
    final List<dynamic> mediaList = tip['media'] is List ? tip['media'] : [];
    final bool hasMedia = mediaList.isNotEmpty;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 제목 표시
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 2. 본문 내용 (content) - 단일 Text에서 목록 위젯으로 대체
            ..._buildContentList(content),

            // 미디어가 있을 경우에만 간격 추가
            if (hasMedia) const SizedBox(height: 20),

            // 3. 미디어 위젯 목록 (동영상/이미지)
            ..._buildMediaList(context, mediaList),

            // 4. 상세 정보 (details)
            if (details.isNotEmpty) ...[
              // ❌ '상세 정보:' 제목을 제거했습니다.
              const SizedBox(height: 16), // 미디어와 상세 정보 텍스트 간의 간격
              Text(details, style: const TextStyle(fontSize: 15)),
            ],
          ],
        ),
      ),
    );
  }
}