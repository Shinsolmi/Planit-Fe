// lib/screens/recommendation_result_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../services/auth_storage.dart';
import 'completion_screen.dart';

class RecommendationResultScreen extends StatefulWidget {
  const RecommendationResultScreen({super.key, required this.plan});
  final Map<String, dynamic> plan;

  @override
  State<RecommendationResultScreen> createState() => _RecommendationResultScreenState();
}

class _RecommendationResultScreenState extends State<RecommendationResultScreen> {
  bool _saving = false;

  // 파싱된 일정 (일차별)
  late final List<_DayPlan> _days = _parseDetails(widget.plan['details']);

  // details가 List 또는 String(JSON)으로 올 수 있어 방어적으로 파싱
  List<_DayPlan> _parseDetails(dynamic raw) {
    dynamic details = raw;

    // 1) 문자열이면 JSON 파싱 시도
    if (details is String) {
      try {
        details = jsonDecode(details);
      } catch (_) {
        // 파싱 실패 시 빈 목록
        return [];
      }
    }
    if (details is! List) return [];

    // 2) day, plan 배열 구조 파싱
    final result = <_DayPlan>[];
    for (final d in details) {
      if (d is! Map) continue;
      final dayNum = d['day'];
      final plans = d['plan'];
      if (dayNum is! int || plans is! List) continue;

      final items = <_PlanItem>[];
      for (final p in plans) {
        if (p is! Map) continue;
        final time = (p['time'] ?? '').toString();
        final place = (p['place'] ?? '').toString();
        final memo = (p['memo'] ?? '').toString();
        items.add(_PlanItem(time: time, place: place, memo: memo));
      }

      // 3) 시간 오름차순 정렬
      items.sort((a, b) => _timeKey(a.time).compareTo(_timeKey(b.time)));
      result.add(_DayPlan(day: dayNum, items: items));
    }

    // 4) day 오름차순
    result.sort((a, b) => a.day.compareTo(b.day));
    return result;
  }

  // "HH:mm" → 분 단위 키 (형식이 엉켜도 최대한 비교 가능)
  int _timeKey(String t) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(t.trim());
    if (m == null) return 24 * 60 * 10; // 맨 뒤로
    final h = int.tryParse(m.group(1)!) ?? 0;
    final min = int.tryParse(m.group(2)!) ?? 0;
    return h * 60 + min;
    // 필요하면 오전/오후/한글시간 같은 포맷도 여기서 보정 가능
  }

  Future<void> _saveToMySchedules() async {
    setState(() => _saving = true);
    try {
      final jwt = await AuthStorage.getToken();
      final url = Uri.parse('$baseUrl/schedules/save-gpt'); // 엔드포인트 확인
      final res = await http.post(
      url,
        headers: {
          'Content-Type': 'application/json',
          if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'title': 'GPT 추천 일정',
          'destination': widget.plan['city'],
          'startdate': widget.plan['startdate'],
          'enddate': widget.plan['enddate'],
          'details': widget.plan['details'], // 원본 스키마 그대로 전달
        }),
      );

      debugPrint('[SAVE-GPT] status=${res.statusCode}');
      debugPrint('[SAVE-GPT] body=${res.body}');

      if (!mounted) return;
      
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final id = data['scheduleId'] as int;
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CompletionScreen(scheduleId: id)), // ← 전달
        );
      }else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: ${res.statusCode}  ${res.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final city = (widget.plan['city'] ?? '') as String;
    final start = (widget.plan['startdate'] ?? '') as String;
    final end = (widget.plan['enddate'] ?? '') as String;

    return Scaffold(
      appBar: AppBar(title: const Text('추천 결과 미리보기')),
      body: Stack(
        children: [
          if (_days.isEmpty)
            const Center(child: Text('표시할 일정이 없어요. 다시 추천을 받아주세요.'))
          else
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: _days.length,
              itemBuilder: (context, i) {
                final day = _days[i];
                return _DaySection(
                  title: 'Day ${day.day}',
                  subtitle: _subtitle(city, start, end, day.day),
                  items: day.items,
                );
              },
            ),
          // 하단 고정 버튼
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16 + 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveToMySchedules,
                      child: const Text('내 일정으로 담기'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('다시 선택하기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_saving) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  String? _subtitle(String city, String start, String end, int day) {
    // 필요하면 Day별 실제 날짜 계산해서 넣을 수 있음. 지금은 도시/범위만 간단히.
    if ((city + start + end).isEmpty) return null;
    return [if (city.isNotEmpty) city, if (start.isNotEmpty && end.isNotEmpty) '$start ~ $end'].join(' · ');
  }
}

// ---- 뷰 위젯들 ----

class _DaySection extends StatelessWidget {
  const _DaySection({required this.title, this.subtitle, required this.items});
  final String title;
  final String? subtitle;
  final List<_PlanItem> items;

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
            // Day 헤더
            Row(
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                if (subtitle != null)
                  Expanded(
                    child: Text(subtitle!, style: TextStyle(color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // 일정 아이템들
            ...items.map((it) => _PlanTile(item: it)),
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
      leading: Container(
        width: 64,
        alignment: Alignment.centerLeft,
        child: Text(item.time, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      title: Text(item.place, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: item.memo.isNotEmpty ? Text(item.memo, style: TextStyle(color: Colors.grey[700])) : null,
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () {
        // TODO: 상세보기 이동이 필요하면 여기서 처리
      },
    );
  }
}

// ---- 모델 ----

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
