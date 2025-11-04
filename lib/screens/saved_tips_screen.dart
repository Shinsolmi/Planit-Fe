// lib/screens/saved_tips_screen.dart (최종 수정)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../services/auth_storage.dart';
import '../widgets/custom_app_bar.dart';
import 'transport_tip_detail_screen.dart'; // 팁 상세 화면 import

class SavedTipsScreen extends StatefulWidget {
  const SavedTipsScreen({super.key});

  @override
  State<SavedTipsScreen> createState() => _SavedTipsScreenState();
}

class _SavedTipsScreenState extends State<SavedTipsScreen> {
  List<dynamic> _savedTips = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedTips();
  }

  // ✅ 저장된 팁 목록을 서버에서 불러오는 함수
  Future<void> _loadSavedTips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthStorage.getToken();
      if (token == null) {
        if (mounted) setState(() => _error = '로그인이 필요합니다.');
        return;
      }
      
      // API 호출: GET /users/me/saved-tips
      final res = await http.get(
        Uri.parse('$baseUrl/users/me/saved-tips'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final List fetchedTips = jsonDecode(res.body);
        setState(() {
          _savedTips = fetchedTips;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '팁 로드 실패: ${res.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = '네트워크 오류: $e';
        _isLoading = false;
      });
    }
  }
  
  // 날짜 포맷 (예: 2025.10.27 저장)
  String _formatSavedDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr).toLocal();
      return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} 저장';
    } catch (_) {
      return '';
    }
  }

  // ✅ 교통수단 타입에 따른 아이콘 반환 함수 (추가)
  IconData _getTransportIcon(String? type) {
    switch (type?.toLowerCase()) {
      case '택시':
        return Icons.local_taxi;
      case '버스':
        return Icons.directions_bus;
      case '지하철':
        return Icons.subway;
      case '기차':
        return Icons.train;
      default:
        return Icons.help_outline; // 알 수 없는 경우 기본 아이콘
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '저장한 대중교통 팁'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('오류: $_error'))
              : _savedTips.isEmpty
                  ? const Center(child: Text('아직 저장된 교통 팁이 없습니다.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _savedTips.length,
                      itemBuilder: (context, index) {
                        final tip = _savedTips[index];
                        
                        // ⭐️ 이미지 URL 추출: 서버에서 받은 media_url 필드를 사용
                        final String? imageUrl = tip['media_url']; 
                        final String fullImageUrl = (imageUrl != null && imageUrl.isNotEmpty) ? '$baseUrl/$imageUrl' : '';

                        // ✅ 이미지 표시 및 왼쪽 정렬
                        final Widget leadingWidget = fullImageUrl.isNotEmpty
                            ? SizedBox(
                                width: 60,
                                height: 60,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    fullImageUrl, 
                                    fit: BoxFit.cover,
                                    // 로드 실패 시 교통수단 아이콘 사용
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(_getTransportIcon(tip['transport_type']), size: 30, color: Colors.grey),
                                  ),
                                ),
                              )
                            : Icon(_getTransportIcon(tip['transport_type']), color: Colors.grey); // 이미지가 없을 때 교통수단 아이콘
                        
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: leadingWidget, // ✅ 이미지 또는 교통수단 아이콘 표시
                            title: Text(tip['title'] ?? '제목 없음', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              // tip['id']는 서버에서 tip_id로 받은 값입니다.
                              '${tip['country'] ?? ''} - ${tip['transport_type'] ?? ''} ${_formatSavedDate(tip['saved_at'])}',
                            ),
                            onTap: () {
                              // 팁 상세 화면으로 이동 (TransportTipDetailScreen)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  // tip 객체 전체를 전달 
                                  builder: (_) => TransportTipDetailScreen(tip: tip), 
                                ),
                              ).then((_) => _loadSavedTips()); // 돌아올 때 목록 갱신
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}