// lib/screens/transport_tip_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../widgets/custom_app_bar.dart';

class TransportTipDetailScreen extends StatelessWidget {
  final Map<String, dynamic> tip;

  const TransportTipDetailScreen({
    super.key,
    required this.tip,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = tip['title'] ?? '교통 팁';
    final String content = tip['content'] ?? '내용 없음';
    final String mediaUrl = tip['media_url'] ?? ''; 
    final String mediaType = tip['media_type'] ?? ''; 
    final String details = tip['details'] ?? ''; 

    Widget mediaWidget;
    
    if (mediaType == 'image' && mediaUrl.isNotEmpty) {
      mediaWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          mediaUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) => 
            const Icon(Icons.broken_image, size: 100),
        ),
      );
    } else if (mediaType == 'video' && mediaUrl.isNotEmpty) {
      mediaWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _launchUrl(mediaUrl),
            child: const Row(
              children: [
                Icon(Icons.ondemand_video, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  '동영상 링크 보기 (클릭)', 
                  style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mediaUrl,
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
        ],
      );
    } else {
      mediaWidget = const SizedBox.shrink();
    }

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
            
            // 2. 본문 내용 (content)
            Text(content, style: const TextStyle(fontSize: 16)),
            
            // 미디어가 있을 경우에만 간격 추가
            if (mediaUrl.isNotEmpty) const SizedBox(height: 20),

            // ✅ 3. 미디어 위젯 (동영상/이미지) - 본문 내용 아래, 상세 정보 위
            mediaWidget,

            // 4. 상세 정보 (details)
            if (details.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('상세 정보:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(details, style: const TextStyle(fontSize: 15)),
            ],
          ],
        ),
      ),
    );
  }
}