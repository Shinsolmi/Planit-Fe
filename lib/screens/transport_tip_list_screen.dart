// lib/screens/transport_tip_list_screen.dart (새로 생성 및 기능 구현)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../services/auth_storage.dart';
import '../widgets/custom_app_bar.dart';
import 'transport_tip_detail_screen.dart'; // 팁 상세 화면 import

class TransportTipListScreen extends StatefulWidget {
  final String transportType;
  // ⚠️ 현재는 country가 하드코딩되거나 다른 화면에서 넘어와야 합니다. 여기서는 '일본'으로 가정합니다.
  final String country = '일본'; 

  const TransportTipListScreen({super.key, required this.transportType});

  @override
  State<TransportTipListScreen> createState() => _TransportTipListScreenState();
}

class _TransportTipListScreenState extends State<TransportTipListScreen> {
  List<dynamic> _tips = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  // ✅ 교통수단 타입에 따른 아이콘 반환 함수
  IconData _getTransportIcon(String? type) {
    switch (type?.toLowerCase().trim()) {
      case '택시':
        return Icons.local_taxi;
      case '버스':
      case '고속버스':
        return Icons.directions_bus;
      case '지하철':
        return Icons.subway;
      case '기차':
        return Icons.train;
      default:
        return Icons.help_outline;
    }
  }

  // ✅ 팁 목록을 서버에서 불러오는 함수
  Future<void> _loadTips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('$baseUrl/tips')
          .replace(queryParameters: {
            'type': widget.transportType,
            'country': widget.country,
          });

      // ⚠️ 서버의 tips.js가 media 정보를 함께 반환해야 상세 이미지가 보입니다.
      final res = await http.get(uri);

      if (!mounted) return;

      if (res.statusCode == 200) {
        final List fetchedTips = jsonDecode(res.body);
        setState(() {
          _tips = fetchedTips;
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
  
  @override
  Widget build(BuildContext context) {
    // AppBar 제목 설정
    final String appBarTitle = '${widget.country} ${widget.transportType} 팁';

    return Scaffold(
      appBar: CustomAppBar(title: appBarTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('오류: $_error'))
              : _tips.isEmpty
                  ? Center(child: Text('${widget.transportType} 팁이 없습니다.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tips.length,
                      itemBuilder: (context, index) {
                        final tip = _tips[index];
                        
                        // ⭐️ 썸네일 자리에 교통수단 아이콘 표시 (핵심 수정)
                        final IconData transportIcon = _getTransportIcon(widget.transportType);

                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            // ✅ 썸네일 자리: 교통수단 아이콘을 썸네일 모양 박스에 넣어 표시
                            leading: Container(
                              width: 48,
                              height: 48,
                             
                              child: Icon(transportIcon, size: 28),
                            ),
                            
                            title: Text(tip['title'] ?? '제목 없음', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(tip['content'] ?? '내용 없음', maxLines: 2, overflow: TextOverflow.ellipsis),
                            
                            onTap: () {
                              // 팁 상세 화면으로 이동 (TransportTipDetailScreen)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  // tip 객체 전체를 전달 
                                  builder: (_) => TransportTipDetailScreen(tip: tip), 
                                ),
                              ).then((_) => _loadTips()); // 돌아올 때 목록 갱신
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}