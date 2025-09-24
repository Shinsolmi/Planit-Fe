// lib/screens/my_schedules_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../env.dart';
import '../services/auth_storage.dart';
import 'schedule_detail_screen.dart';

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
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await AuthStorage.getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/schedules/me'),
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        final List list = (body is List) ? body : (body['schedules'] as List? ?? []);
        _items = list
            .map((e) => _ScheduleSummary.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.start.compareTo(a.start));
        if (!mounted) return;
        setState(() => _loading = false);
      } else {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = '목록을 불러오지 못했어요 (${res.statusCode})';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '네트워크 오류: $e';
      });
    }
  }

  Future<void> _refresh() async => _load();

  Future<void> _deleteSchedule(int scheduleId, {String? title}) async {
    // 1) 확인 다이얼로그
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: Text(title == null ? '되돌릴 수 없습니다.' : '“$title” 일정을 삭제합니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final token = await AuthStorage.getToken();
      final uri = Uri.parse('$baseUrl/schedules/$scheduleId');
      final res = await http.delete(
        uri,
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        _snack('삭제 완료');
        await _load(); // 성공 시 목록 재조회
      } else if (res.statusCode == 403) {
        _snack('삭제 권한이 없습니다.');
      } else {
        _snack('삭제 실패: ${res.statusCode}');
      }
    } catch (e) {
      _snack('네트워크 오류: $e');
    }
  }

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
                          final subtitleLine = [
                            if (s.destination.isNotEmpty) s.destination,
                            '${_fmtYMD(s.start)} ~ ${_fmtYMD(s.end)}',
                          ].join(' · ');

                          // 스와이프 삭제 + 아이콘 삭제 둘 다 제공
                          return Dismissible(
                            key: ValueKey('schedule_${s.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              color: Theme.of(context).colorScheme.error.withOpacity(0.12),
                              child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                            ),
                            confirmDismiss: (_) async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('삭제할까요?'),
                                  content: Text('“${s.title}” 일정을 삭제합니다.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
                                  ],
                                ),
                              );
                              return ok == true;
                            },
                            onDismissed: (_) => _deleteSchedule(s.id, title: s.title),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(subtitleLine),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: '삭제',
                                  onPressed: () => _deleteSchedule(s.id, title: s.title),
                                ),
                                onTap: () async {
                                  // 상세로 이동 → 변경 여부를 결과로 받아오면 목록 갱신
                                  final changed = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ScheduleDetailScreen(scheduleId: s.id),
                                    ),
                                  );
                                  if (changed == true) {
                                    await _load();
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _fmtYMD(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
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
            const Icon(Icons.error_outline, size: 48),
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
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return DateTime.tryParse(s.substring(0, s.length >= 10 ? 10 : s.length))?.toLocal() ?? DateTime.now();
    }
  }

  factory _ScheduleSummary.fromJson(Map<String, dynamic> json) {
    return _ScheduleSummary(
      id: (json['schedule_id'] ?? json['id']) as int,
      title: (json['title'] ?? '').toString(),
      destination: (json['destination'] ?? '').toString(),
      start: _parseDate(json['startdate']),
      end: _parseDate(json['enddate']),
    );
  }
}
