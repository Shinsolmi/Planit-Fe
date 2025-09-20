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
  bool _selectMode = false;                       // 선택 모드 on/off
  final Set<_PickedPlace> _picked = {};           // 제외할 아이템 모음

  void _toggleSelectMode() => setState(() => _selectMode = !_selectMode);

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
    final url = Uri.parse('$baseUrl/schedules/save-gpt');

    // plan에서 받은 값
    final start = widget.plan['startdate'] as String?;
    final end   = widget.plan['enddate'] as String?;

    // 조건부 payload 구성
    final payload = <String, dynamic>{
      'title': (widget.plan['title'] ?? '추천 일정').toString(),
      'destination': widget.plan['city'],
      'details': widget.plan['details'],                  // [{day, plan:[...]}]
      'duration': _days.isNotEmpty ? _days.length : null, // 일수 fallback
    };

    // start/end가 있으면 포함 (없으면 서버가 duration으로 계산)
    if (start != null && start.isNotEmpty) payload['startdate'] = start;
    if (end != null && end.isNotEmpty)     payload['enddate']   = end;

    // null/빈값 제거 (duration이 null이면 자동 제외)
    payload.removeWhere((k, v) => v == null || (v is String && v.isEmpty));

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode(payload),
    );

    debugPrint('[SAVE-GPT] status=${res.statusCode}');
    debugPrint('[SAVE-GPT] body=${res.body}');

    if (!mounted) return;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      Map<String, dynamic>? data;
      try { data = jsonDecode(res.body) as Map<String, dynamic>; } catch (_) {}
      final id = data?['scheduleId'] as int?;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CompletionScreen(scheduleId: id)),
      );
    } else {
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

Future<void> _refineByRemovingPicked() async {
  if (_picked.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('제외할 장소를 선택해 주세요.')),
    );
    return;
  }
  setState(() => _saving = true);
  try {
    final jwt = await AuthStorage.getToken();
    final uri = Uri.parse('$baseUrl/ai/schedule-refine-diff');

    final remove = _picked
        .map((e) => {'day': e.day, 'time': e.time, 'place': e.place})
        .toList();

    final payload = {
      'city': widget.plan['city'],
      if (widget.plan['startdate'] != null) 'startdate': widget.plan['startdate'],
      if (widget.plan['enddate']   != null) 'enddate':   widget.plan['enddate'],
      'duration': _days.length,
      'baseDetails': widget.plan['details'],
      'remove': remove,
      'policy': 'keep-others',
    };

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode(payload),
    );

    debugPrint('[REFINE-DIFF] status=${res.statusCode}');
    debugPrint('[REFINE-DIFF] body=${res.body}');

    if (!mounted) return;

    // ✅ 422 처리: 최소 개수 미달/빈 일차
    if (res.statusCode == 422) {
      try {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        final lacks = (m['lacks'] as List? ?? const [])
            .map((e) => (e as Map)['day'])
            .where((d) => d != null)
            .join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일부 일차가 충분히 채워지지 않았어요 (day: $lacks). 항목을 덜 빼거나 다시 시도해 주세요.')),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('추천이 충분하지 않아요. 다시 시도해 주세요.')),
        );
      }
      setState(() => _saving = false); // 선택모드 유지
      return;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final newPlan = jsonDecode(res.body) as Map<String, dynamic>;

      // (옵션) 빈 결과 가드
      if (_allDaysEmpty(newPlan)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('추천 결과가 비어 있어요. 다른 항목을 선택하거나 다시 시도해 주세요.')),
        );
        setState(() => _saving = false);
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RecommendationResultScreen(plan: newPlan)),
      );
      return;
    }

    // 그 외 실패
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('재추천 실패: ${res.statusCode} ${res.body}')),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('오류: $e')),
    );
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final city = (widget.plan['city'] ?? '') as String;
    final start = (widget.plan['startdate'] ?? '') as String;
    final end = (widget.plan['enddate'] ?? '') as String;
    final title = (widget.plan['title'] ?? '추천 결과 미리보기').toString();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: [
          if (_days.isEmpty)
            const Center(child: Text('표시할 일정이 없어요. 다시 추천을 받아주세요.'))
          else
          // ✅ 선택모드/체크 반영 버전
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: _days.length,
            itemBuilder: (context, i) {
              final day = _days[i];
              return _DaySection(
                day: day.day, // ✅ 필수
                items: day.items,
                subtitle: _subtitle(city, start, end, day.day),
                // 선택 모드 쓰는 경우에만 ↓ 추가
                selectMode: _selectMode,
                isPicked: (it) => _picked.contains(
                  _PickedPlace(day: day.day, time: it.time, place: it.place),
                ),
                onPickToggle: (it, pick) {
                  setState(() {
                    final ref = _PickedPlace(day: day.day, time: it.time, place: it.place);
                    if (pick) _picked.add(ref); else _picked.remove(ref);
                  });
                },
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
                      onPressed: _saving ? null : () {
                        if (_selectMode) {
                          _refineByRemovingPicked();        // 선택완료 → 재추천 호출
                        } else {
                          _toggleSelectMode();               // 선택모드 켜기
                        }
                      },
                      child: Text(_selectMode ? '선택 완료' : '부분 재추천'),
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
    
    bool _allDaysEmpty(Map<String, dynamic> plan) {
      final details = plan['details'];
      if (details is! List) return true;
      for (final d in details) {
        final list = (d is Map) ? d['plan'] : null;
        if (list is List && list.isNotEmpty) return false;
      }
      return true;
    }
}

// ---- 뷰 위젯들 ----
// ✅ 기존 _DaySection 교체
class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.items,
    this.subtitle,
    // ⬇️ 추가된 선택 파라미터들
    this.selectMode = false,
    this.isPicked,
    this.onPickToggle,
  });

  final int day;
  final List<_PlanItem> items;
  final String? subtitle;

  // ⬇️ 추가
  final bool selectMode;
  final bool Function(_PlanItem item)? isPicked;
  final void Function(_PlanItem item, bool pick)? onPickToggle;

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
                  Expanded(child: Text(subtitle!, style: TextStyle(color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((it) => _PlanTile(
                  day: day,
                  item: it,
                  selectMode: selectMode,                 // ⬅️ 추가
                  picked: isPicked?.call(it) ?? false,    // ⬅️ 추가
                  onPickToggle: onPickToggle,             // ⬅️ 추가
                )),
          ],
        ),
      ),
    );
  }
}

// ✅ 기존 _PlanTile 교체
class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.day,
    required this.item,
    // ⬇️ 추가된 선택 파라미터들 (기본값 있음)
    this.selectMode = false,
    this.picked = false,
    this.onPickToggle,
  });

  final int day;
  final _PlanItem item;

  // ⬇️ 추가
  final bool selectMode;
  final bool picked;
  final void Function(_PlanItem item, bool pick)? onPickToggle;

  @override
  Widget build(BuildContext context) {
    if (!selectMode) {
      // 기존 모드
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: SizedBox(width: 64, child: Text(item.time, style: const TextStyle(fontWeight: FontWeight.w600))),
        title: Text(item.place, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: item.memo.isNotEmpty ? Text(item.memo, style: TextStyle(color: Colors.grey[700])) : null,
        trailing: const Icon(Icons.chevron_right, size: 18),
      );
    }
    // 선택 모드: 체크박스
    return CheckboxListTile(
      value: picked,
      onChanged: (v) => onPickToggle?.call(item, v ?? false),
      dense: true,
      contentPadding: EdgeInsets.zero,
      secondary: SizedBox(width: 64, child: Text(item.time, style: const TextStyle(fontWeight: FontWeight.w600))),
      title: Text(item.place, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: item.memo.isNotEmpty ? Text(item.memo, style: TextStyle(color: Colors.grey[700])) : null,
      controlAffinity: ListTileControlAffinity.leading,
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

class _PickedPlace {
  final int day;
  final String time;
  final String place;
  const _PickedPlace({required this.day, required this.time, required this.place});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PickedPlace && day == other.day && time == other.time && place == other.place;

  @override
  int get hashCode => Object.hash(day, time, place);
}
