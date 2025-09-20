import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planit/env.dart';
import 'package:planit/services/auth_storage.dart';

/// 사용법:
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => ScheduleDetailScreen(data: responseJsonMap),
/// ));
class ScheduleDetailScreen extends StatefulWidget {
  const ScheduleDetailScreen({
    super.key,
    this.data,           // 이미 받아온 데이터가 있으면 바로 렌더
    this.scheduleId,     // 아니면 이 id로 서버에서 조회
  }) : assert(data != null || scheduleId != null,
       'data 또는 scheduleId 중 하나는 필요합니다');

  final Map<String, dynamic>? data;
  final int? scheduleId;

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _data = widget.data;
      _loading = false;
    } else {
      _loadById();
    }
  }

  Future<void> _loadById() async {
    setState(() { _loading = true; });
    try {
      final id = widget.scheduleId; // 화면 생성 시 넘겨준 id
      if (id == null) {
        debugPrint('[DETAIL] scheduleId=null');
        setState(() { _data = null; });
        return;
      }

      final jwt = await AuthStorage.getToken();
      final uri = Uri.parse('$baseUrl/schedules/$id');
      debugPrint('➡️ GET $uri');
      final res = await http.get(
        uri,
        headers: {
          if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt', // ✅ 필수
        },
      );
      debugPrint('⬅️ status=${res.statusCode}');
      debugPrint('⬅️ body=${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() { _data = map; });
      } else {
        // 상태/바디 그대로 보여주면 원인 파악 쉬움
        setState(() { _data = null; });
        // 원하면 스낵바로 즉시 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('상세 실패: ${res.statusCode} ${res.body}')),
          );
        }
      }
    } catch (e) {
      debugPrint('[DETAIL] error: $e');
      setState(() { _data = null; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('네트워크 오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_data == null) return const Scaffold(body: Center(child: Text('일정을 불러올 수 없어요.')));
    // ⬇️ 기존 detail 렌더링 코드 사용
    return _buildDetail(_data!);
  }

  Widget _buildDetail(Map<String, dynamic> data) {
    // 1) 스케줄 메타 파싱
    final schedule = (data['schedule'] as Map<String, dynamic>?) ?? const {};
    final String title = (schedule['title'] ?? '상세 일정').toString();
    final String destination = (schedule['destination'] ?? '').toString();
    final String start = _safeDateString(schedule['startdate']);
    final String end   = _safeDateString(schedule['enddate']);

    // 2) 상세 파싱 (day/time 정렬 포함)
    final List<_DayPlan> parsed = _parseDetails(data['details']);

    // 3) UI
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: parsed.isEmpty
          ? const Center(child: Text('등록된 상세 일정이 없습니다.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: parsed.length + 1, // 상단 요약 + 일차 섹션들
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _HeaderCard(
                    destination: destination,
                    start: start,
                    end: end,
                    totalDays: parsed.length,
                  );
                }
                final dayPlan = parsed[index - 1];
                return _DaySection(
                  day: dayPlan.day,
                  items: dayPlan.items,
                  // subtitle: '$start ~ $end', // 원하면 주석 해제
                );
              },
            ),
    );
  }

  // ---- helper funcs (함수 밖 전역) ----

  List<_DayPlan> _parseDetails(dynamic raw) {
    dynamic details = raw;
    if (details is String) {
      try { details = jsonDecode(details); } catch (_) { return []; }
    }
    if (details is! List) return [];

    final result = <_DayPlan>[];
    for (final d in details) {
      if (d is! Map) continue;
      final dayNum = d['day'];
      final plans = d['plan'];
      if (dayNum is! int || plans is! List) continue;

      final items = <_PlanItem>[];
      for (final p in plans) {
        if (p is! Map) continue;
        final rawTime = (p['time'] ?? '').toString();
        final time = _prettyTime(rawTime); // 'HH:mm:ss' -> 'HH:mm'
        final place = (p['place'] ?? '').toString();
        final memo = (p['memo'] ?? '').toString();
        items.add(_PlanItem(time: time, place: place, memo: memo));
      }
      // 시간 오름차순
      items.sort((a, b) => _timeKey(a.time).compareTo(_timeKey(b.time)));
      result.add(_DayPlan(day: dayNum, items: items));
    }
    // day 오름차순
    result.sort((a, b) => a.day.compareTo(b.day));
    return result;
  }

  String _prettyTime(String raw) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(raw.trim());
    if (m == null) return raw;
    final hh = m.group(1)!.padLeft(2, '0');
    final mm = m.group(2)!;
    return '$hh:$mm';
  }

  int _timeKey(String t) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(t.trim());
    if (m == null) return 24 * 60 * 10;
    final h = int.tryParse(m.group(1)!) ?? 0;
    final min = int.tryParse(m.group(2)!) ?? 0;
    return h * 60 + min;
  }

  String _safeDateString(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
}
// ---- 모델 (전역 스코프에 두세요) ----
class _DayPlan {
  final int day;
  final List<_PlanItem> items;
  _DayPlan({required this.day, required this.items});
}

class _PlanItem {
  final String time;
  final String place;
  final String memo;
  _PlanItem({required this.time, required this.place, required this.memo});
}


  /// 상단 요약 카드
  class _HeaderCard extends StatelessWidget {
    const _HeaderCard({
      required this.destination,
      required this.start,
      required this.end,
      required this.totalDays,
    });

    final String destination;
    final String start;
    final String end;
    final int totalDays;

    @override
    Widget build(BuildContext context) {
      final nights = totalDays > 0 ? totalDays - 1 : 0;
      final line = [
        if (destination.isNotEmpty) destination,
        if (start.isNotEmpty && end.isNotEmpty) '$start ~ $end',
        if (totalDays > 0) '${nights}박 ${totalDays}일',
      ].join(' · ');

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.event_note),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  line.isEmpty ? '여행 일정' : line,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Day 섹션 + 아이템
  class _DaySection extends StatelessWidget {
    const _DaySection({required this.day, required this.items, this.subtitle});
    final int day;
    final List<_PlanItem> items;
    final String? subtitle;

    @override
    Widget build(BuildContext context) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Day $day', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  if (subtitle != null)
                    Expanded(
                      child: Text(
                        subtitle!,
                        style: TextStyle(color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ...items.map((e) => _PlanTile(item: e)),
            ],
          ),
        ),
      );
    }
  }

  class _PlanTile extends StatelessWidget {
    const _PlanTile({required this.item});
    final _PlanItem item;

    @override
    Widget build(BuildContext context) {
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: SizedBox(
          width: 64,
          child: Text(item.time, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        title: Text(item.place, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: item.memo.isNotEmpty
            ? Text(item.memo, style: TextStyle(color: Colors.grey[700]))
            : null,
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () {
          // TODO: 필요하면 상세 보기/지도 이동
        },
      );
    }
  }
