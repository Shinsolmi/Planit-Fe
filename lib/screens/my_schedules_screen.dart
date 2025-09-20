// lib/screens/my_schedules_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../env.dart';
import '../services/auth_storage.dart';
import 'schedule_detail_screen.dart'; // 상세 화면( scheduleId 받아 내부에서 GET 해오는 버전 추천 )

class MySchedulesScreen extends StatefulWidget {
  const MySchedulesScreen({super.key});

  @override
  State<MySchedulesScreen> createState() => _MySchedulesScreenState();
}

class _MySchedulesScreenState extends State<MySchedulesScreen> {
  bool _loading = true;
  String? _error;
  List<_ScheduleSummary> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await AuthStorage.getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/schedules/me'), // ← 필요시 /schedules/mine 등으로 변경
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        // 응답이 [{schedule_id, title, destination, startdate, enddate}, ...]라고 가정
        final List list = (body is List) ? body : (body['schedules'] as List? ?? []);
        _items = list.map((e) => _ScheduleSummary.fromJson(e as Map<String, dynamic>)).toList()
          ..sort((a, b) => b.start.compareTo(a.start)); // 최신 먼저
        setState(() => _loading = false);
      } else {
        setState(() {
          _loading = false;
          _error = '목록을 불러오지 못했어요 (${res.statusCode})';
          
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '네트워크 오류: $e';
      });
    }
  }

  Future<void> _refresh() async => _load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 일정')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? _ErrorView(message: _error!, onRetry: _load)
              : (_items.isEmpty)
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final s = _items[i];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              title: Text(
                                s.title,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                [
                                  if (s.destination.isNotEmpty) s.destination,
                                  '${_fmtYMD(s.start)} ~ ${_fmtYMD(s.end)}',
                                ].join(' · '),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ScheduleDetailScreen(scheduleId: s.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _fmtYMD(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ------- 뷰 보조 위젯 -------

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('아직 저장된 일정이 없어요.'),
            const SizedBox(height: 4),
            Text(
              '추천을 받아 저장하거나 새 여행을 만들어 보세요.',
              style: TextStyle(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

// ------- 모델 -------

class _ScheduleSummary {
  final int id;
  final String title;
  final String destination;
  final DateTime start;
  final DateTime end;

  _ScheduleSummary({
    required this.id,
    required this.title,
    required this.destination,
    required this.start,
    required this.end,
  });

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    final s = v.toString();
    // 'YYYY-MM-DD' or ISO → DateTime
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      // 포맷이 애매하면 앞 10자리 시도
      return DateTime.tryParse(s.substring(0, s.length >= 10 ? 10 : s.length))?.toLocal() ?? DateTime.now();
    }
  }

  factory _ScheduleSummary.fromJson(Map<String, dynamic> json) {
    return _ScheduleSummary(
      id: (json['schedule_id'] ?? json['id']) as int, // 백엔드 키명 호환
      title: (json['title'] ?? '').toString(),
      destination: (json['destination'] ?? '').toString(),
      start: _parseDate(json['startdate']),
      end: _parseDate(json['enddate']),
    );
    // 필요하면 user_id 등 추가
  }
}
