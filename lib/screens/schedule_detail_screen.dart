import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planit/env.dart';
import 'package:planit/services/auth_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'search_page.dart';

class ScheduleDetailScreen extends StatefulWidget {
  const ScheduleDetailScreen({
    super.key,
    this.data,
    this.scheduleId,
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
  bool _editingMode = false;
  bool _changed = false;
  bool _webReady = false;   // /map 로드 완료
  bool _dataReady = false;  // _data 로드 완료
  bool _mapReady = false;
  late final WebViewController _mapCtrl;

  void _toggleEditingMode() {
    setState(() => _editingMode = !_editingMode);
    _snack(_editingMode ? '편집 모드: 수정할 장소를 탭하거나 새로운 장소를 추가하세요.' : '편집 모드 종료');
  }

  @override
  void initState() {
    super.initState();

    _webReady  = false;
    _dataReady = widget.data != null; // data를 넘겨받았다면 true
    _mapCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            _webReady = false; // ✨ 새 페이지 시작마다 리셋
          },
          onPageFinished: (_) async {
            _webReady = true;
            await _tryInject(); // 준비가 되면 주입 시도
          },
        ),
      );

    // ✨ 캐시버스터 추가
    final ts  = DateTime.now().millisecondsSinceEpoch;
    final sep = mapPagePath.contains('?') ? '&' : '?';
    _mapCtrl.loadRequest(Uri.parse('$webBaseUrl$mapPagePath${sep}v=$ts'));

    if (widget.data != null) {
      _data = widget.data;
      _loading = false;
      _dataReady = true;
      _tryInject(); // 혹시 이미 웹이 준비됐으면 즉시 시도
    } else {
      _loadById();  // 로딩 끝나면 _dataReady=true로 세팅해주기
    }
  }

  Future<void> _loadById() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final id = widget.scheduleId;
      if (id == null) {
        debugPrint('[DETAIL] scheduleId=null');
        setState(() {
          _data = null;
          _loading = false;
          _dataReady = false;
        });
        return;
      }

      final jwt = await AuthStorage.getToken();
      final uri = Uri.parse('$baseUrl/schedules/$id');

      final response = await http
          .get(
            uri,
            headers: {
              if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
            },
          )
          .timeout(const Duration(seconds: 12));

      debugPrint('GET $uri -> ${response.statusCode}');
      // debugPrint(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final map = jsonDecode(response.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _data = map;
          _loading = false;
          _dataReady = true; // ✅ 중요
        });
        await _tryInject();   // ✅ 중요: 웹뷰 준비됐다면 지도에 주입
      } else {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _dataReady = false;
        });
        final bodyShort = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상세 실패: ${response.statusCode} $bodyShort')),
        );
      }
    } catch (e) {
      debugPrint('[DETAIL] error: $e');
      if (!mounted) return;
      setState(() {
        _data = null;
        _loading = false;
        _dataReady = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  Future<void> _tryInject() async {
    if (!_webReady || !_dataReady) return;

    // JS 준비(google & setSchedules) 폴링: 최대 5초
    bool ready = false;
    for (int i = 0; i < 50; i++) {
      final ok = await _mapCtrl.runJavaScriptReturningResult(
        "typeof google!=='undefined' && !!google.maps && typeof window.setSchedules==='function'"
      );
      if ('$ok' == 'true') { ready = true; break; }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!ready) return;

    // (선택) 안전 리셋 한번
    await _mapCtrl.runJavaScript("window.__reset && window.__reset();");

    // 힌트 먼저
    final schedule = (_data?['schedule'] as Map<String, dynamic>?) ?? {};
    final hint = (schedule['destination'] ?? schedule['title'] ?? '').toString();
    await _mapCtrl.runJavaScript(
      "window.setMapContext && window.setMapContext({ hint: ${jsonEncode(hint)}, radiusKm: 60 });"
    );

    // 상세 데이터 전달 (좌표/숙소 포함)
    final parsed = _parseDetails(_data?['details']);
    final detailsJson = jsonEncode(parsed.map((d)=> {
      'day': d.day,
      'plan': d.items.map((it)=> {
        'place': it.place,
        'time' : it.time,
        'memo' : it.memo,
        if (it.loc != null) 'loc': it.loc,       // ✅ lat/lng 전달
        'is_lodging': it.isLodging,              // ✅ 숙소 표시 전달
      }).toList(),
    }).toList());

    await _mapCtrl.runJavaScript(
      "window.setSchedules && window.setSchedules($detailsJson);"
    );
  }

  Future<void> _saveAllFromParsed(
    List<_DayPlan> parsed, {
    String? overrideTitle,
    String? overrideDestination,
    String? overrideStart,
    String? overrideEnd,
  }) async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final schedule = (_data?['schedule'] as Map<String, dynamic>?) ?? {};
      final payload = {
        'title'      : overrideTitle      ?? (schedule['title'] ?? '').toString(),
        'destination': overrideDestination?? (schedule['destination'] ?? '').toString(),
        'startdate'  : overrideStart      ?? _safeDateString(schedule['startdate']),
        'enddate'    : overrideEnd        ?? _safeDateString(schedule['enddate']),
        'details'    : parsed.map((d) => {
          'day': d.day,
          'plan': d.items
            .where((it) => it.place.trim().isNotEmpty && it.time.trim().isNotEmpty)
            .map((it) {
              final m = <String, dynamic>{
                'time': it.time.length == 5 ? '${it.time}:00' : it.time,
                'place': it.place.trim(),
                'memo': it.memo,
              };

              // ✅ 이 아이템이 "출발지"일 때 다음 지점으로의 이동정보를 원래 위치에 그대로 저장
              if (it.transport != null) {
                m['transportation_to_next'] = it.transport;
              }
              if ((it.optsFromHere ?? const []).isNotEmpty) {
                m['transportation_options'] = it.optsFromHere;
              }

              // ✅ 기타 플래그/좌표도 보존
              if (it.isLodging) m['숙소'] = true;
              if (it.loc != null) m['loc'] = it.loc;
              if (it.mapUrl != null) m['map_url'] = it.mapUrl;

              return m;
            }).toList(),
        }).where((day) => (day['plan'] as List).isNotEmpty).toList(),
      };

      final jwt = await AuthStorage.getToken();
      final id = widget.scheduleId ?? (_data?['schedule']?['schedule_id']);
      final uri = Uri.parse('$baseUrl/schedules/$id/full');

      final res = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode(payload),
      );

      debugPrint('PUT $uri -> ${res.statusCode}');
      debugPrint(res.body);

      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _changed = true;

        bool applied = false;
        try {
          final body = jsonDecode(res.body);
          if (body is Map<String, dynamic> && body.containsKey('schedule')) {
            setState(() {
              _data = body;
              _dataReady = true;
            });
            await _tryInject();
            applied = true;
          }
        } catch (_) {}

        if (!applied) {
          await _loadById();
        }

        if (!mounted) return;
        _snack('저장 완료');
      } else {
        _snack('저장 실패: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      _snack('네트워크 오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ 새로운 메서드: 새 장소 추가
  Future<void> _addPlace() async {
    final parsed = _parseDetails(_data?['details']);
    if (parsed.isEmpty) {
      _snack('추가할 일정이 없습니다. 먼저 일정 기본 정보를 입력해주세요.');
      return;
    }

    final placeCtrl = TextEditingController();
    final memoCtrl = TextEditingController();
    int selectedDay = parsed[0].day;
    TimeOfDay selectedTime = TimeOfDay.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('새 장소 추가'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DayPicker(
                    totalDays: parsed.length,
                    initialDay: selectedDay,
                    onChanged: (day) => setState(() => selectedDay = day),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final pickedTime = await showTimePicker(
                              context: dialogContext,
                              initialTime: selectedTime,
                            );
                            if (pickedTime != null) {
                              setState(() => selectedTime = pickedTime);
                            }
                          },
                          child: Text(_fmt(selectedTime)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: placeCtrl,
                          decoration: const InputDecoration(labelText: '장소(place)'),
                          autofocus: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: memoCtrl,
                    decoration: const InputDecoration(labelText: '메모(memo)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
              FilledButton(
                onPressed: () {
                  if (placeCtrl.text.trim().isEmpty) {
                    _snack('장소를 입력하세요.');
                    return;
                  }
                  Navigator.pop(ctx, {
                    'day': selectedDay,
                    'time': _fmt(selectedTime),
                    'place': placeCtrl.text.trim(),
                    'memo': memoCtrl.text.trim(),
                  });
                },
                child: const Text('추가'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      final newParsed = _parseDetails(_data?['details']);
      final dayIndex = newParsed.indexWhere((d) => d.day == result['day']);

      final newItem = _PlanItem(
        time: result['time']!,
        place: result['place']!,
        memo: result['memo']!,
      );

      if (dayIndex != -1) {
        newParsed[dayIndex].items.add(newItem);
      } else {
        newParsed.add(_DayPlan(day: result['day'], items: [newItem]));
      }

      await _saveAllFromParsed(newParsed);
    }
  }

  Future<void> _openEditSheet({
    required int dayIndex,
    required int itemIndex,
  }) async {
    final parsed = _parseDetails(_data?['details']);
    final item = parsed[dayIndex].items[itemIndex];

    final placeCtrl = TextEditingController(text: item.place);
    final memoCtrl = TextEditingController(text: item.memo);
    TimeOfDay? time = _parseHHmm(item.time);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('상세 일정 편집', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: placeCtrl,
                decoration: InputDecoration(
                  labelText: '장소(place)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () async {
                      // 검색 로직 필요시 추가
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: time ?? const TimeOfDay(hour: 10, minute: 0),
                        );
                        if (picked != null) {
                          time = picked;
                          (context as Element).markNeedsBuild();
                        }
                      },
                      child: Text(time != null ? _fmt(time!) : '시간 선택'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: memoCtrl,
                      decoration: const InputDecoration(labelText: '메모(memo)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final place = placeCtrl.text.trim();
                    if (place.isEmpty) {
                      _snack('장소를 입력하세요');
                      return;
                    }
                    final hhmm = time != null ? _fmt(time!) : item.time;
                    Navigator.pop(context);

                    final newParsed = _parseDetails(_data?['details']);
                    newParsed[dayIndex].items[itemIndex] =
                        _PlanItem(time: hhmm, place: place, memo: memoCtrl.text.trim());

                    await _saveAllFromParsed(newParsed);
                  },
                  child: const Text('저장'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEditTitleDialog() async {
    if (!mounted) return;

    final schedule = (_data?['schedule'] as Map<String, dynamic>?) ?? {};
    final currentTitle = (schedule['title'] ?? '').toString();
    final parsed = _parseDetails(_data?['details']);

    final ctrl = TextEditingController(text: currentTitle);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('제목 수정'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '새 제목을 입력하세요'),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('저장')),
        ],
      ),
    );

    if (ok == true) {
      final newTitle = ctrl.text.trim();
      if (newTitle.isEmpty) {
        _snack('제목을 입력하세요');
        return;
      }
      await _saveAllFromParsed(parsed, overrideTitle: newTitle);
    }
  }

  Future<void> _confirmDelete({required int dayIndex, required int itemIndex}) async {
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: const Text('되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (ok == true) {
      if (!mounted) return;

      final newParsed = _parseDetails(_data?['details']);
      newParsed[dayIndex].items.removeAt(itemIndex);
      if (newParsed[dayIndex].items.isEmpty) newParsed.removeAt(dayIndex);

      await _saveAllFromParsed(newParsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _changed);
      },
      child: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (_data == null
              ? const Scaffold(body: Center(child: Text('등록된 상세 일정이 없습니다.')))
              : _buildDetail(_data!)),
    );
  }

  Widget _buildDetail(Map<String, dynamic> data) {
    final schedule = (data['schedule'] as Map<String, dynamic>?) ?? const {};
    final String title = (schedule['title'] ?? '상세 일정').toString();
    final String destination = (schedule['destination'] ?? '').toString();
    final String start = _safeDateString(schedule['startdate']);
    final String end   = _safeDateString(schedule['enddate']);

    final List<_DayPlan> parsed = _parseDetails(data['details']);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_editingMode) ...[
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              iconSize: 28,
              color: Theme.of(context).colorScheme.primary,
              onPressed: _addPlace,
            ),
            IconButton(
              icon: const Icon(Icons.title_rounded),
              iconSize: 28,
              color: Theme.of(context).colorScheme.primary,
              onPressed: _openEditTitleDialog,
            ),
            IconButton(
              icon: const Icon(Icons.check_rounded, color: Colors.green),
              iconSize: 30,
              onPressed: () {
                setState(() => _editingMode = false);
                _snack('편집 모드 종료');
              },
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              iconSize: 32,
              color: Theme.of(context).colorScheme.primary,
              onPressed: _toggleEditingMode,
            ),
        ],
        bottom: _editingMode
            ? const PreferredSize(
                preferredSize: Size.fromHeight(28),
                child: SizedBox(
                  height: 28,
                  child: Center(
                    child: Text(
                      '편집 모드: 장소를 탭하면 수정 / 휴지통으로 삭제',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: parsed.isEmpty
          ? const Center(child: Text('등록된 상세 일정이 없습니다.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: parsed.length + 2,
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
                if (index == 1) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 280,
                      child: WebViewWidget(controller: _mapCtrl),
                    ),
                  );
                }
                final dayPlan = parsed[index - 2]; // ← 오프셋 2
                return _DaySection(
                  day: dayPlan.day,
                  items: dayPlan.items,
                  editing: _editingMode,
                  onEdit: (i) => _openEditSheet(dayIndex: index - 2, itemIndex: i),
                  onDelete: (i) => _confirmDelete(dayIndex: index - 2, itemIndex: i),
                );
              },
            ),
    );
  }

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
    final plans  = d['plan'];
    if (dayNum is! int || plans is! List) continue;

    final items = <_PlanItem>[];

    for (final p in plans) {
      if (p is! Map) continue;

      final time = _prettyTime((p['time'] ?? '').toString());
      final place = (p['place'] ?? '').toString();
      final memo  = (p['memo']  ?? '').toString();

      final isLodging = (p['숙소'] == true) || (p['is_lodging'] == 1);

      Map<String, dynamic>? transport;
      if (p['transportation_to_next'] is Map) {
        final t = Map<String, dynamic>.from(p['transportation_to_next']);
        transport = {
          'type': (t['type'] ?? t['mode'])?.toString(),
          'duration_min': t['duration_min'],
          'cost_estimate_krw': t['cost_estimate_krw'],
        };
      }

      List<Map<String, dynamic>> options = const [];
      if (p['transportation_options'] is List) {
        options = (p['transportation_options'] as List)
            .where((e) => e is Map)                                  // 1) 먼저 Map인지 확인
            .map<Map<String, dynamic>>((e) {
              final raw = Map<String, dynamic>.from(e as Map);       // 2) 안전 변환
              return {
                'type'            : (raw['type'] ?? raw['mode'])?.toString(),
                'duration_min'    : raw['duration_min'],
                'cost_estimate_krw': raw['cost_estimate_krw'],
              };
            })
            .where((m) => (m['type'] != null))                       // 3) 최종 필터
            .toList(growable: false);
      }

      final Map<String, dynamic>? loc =
          (p['loc'] is Map) ? Map<String, dynamic>.from(p['loc']) : null;
      final String? mapUrl = p['map_url']?.toString();

      items.add(_PlanItem(
        time: time,
        place: place,
        memo: memo,
        isLodging: isLodging,
        transport: transport,
        loc: loc,
        mapUrl: mapUrl,
        optsFromHere: options, // ← 여기 넣어둠
      ));
    }

    // 시간 정렬 (아이템 객체 자체가 움직여도 optsFromHere가 같이 따라다님)
    items.sort((a, b) => _timeKey(a.time).compareTo(_timeKey(b.time)));

    // ✅ 출발지→다음 정보를 "다음" 아이템에 붙일 때, 출발지의 optsFromHere를 그대로 전달
    for (int i = 0; i < items.length - 1; i++) {
      final prev = items[i];
      final next = items[i + 1];
      if (prev.transport != null) {
        items[i + 1] = _PlanItem(
          time: next.time,
          place: next.place,
          memo: next.memo,
          isLodging: next.isLodging,
          transport: next.transport,
          loc: next.loc,
          mapUrl: next.mapUrl,
          transportFromPrev: prev.transport,
          transportOptionsFromPrev: List<Map<String, dynamic>>.from(prev.optsFromHere ?? const []),
          optsFromHere: next.optsFromHere, // 유지
        );
      }
    }
    result.add(_DayPlan(day: dayNum, items: items));
    debugPrint('[UI] day=$dayNum count=${items.length} firstOpts=${items.isNotEmpty ? (items.first.optsFromHere?.length ?? 0) : 0}');
  }

  result.sort((a,b)=>a.day.compareTo(b.day));
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

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  TimeOfDay? _parseHHmm(String s) {
    try {
      final p = s.split(':');
      return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    } catch (_) {
      return null;
    }
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _DayPlan {
  final int day;
  final List<_PlanItem> items;
  _DayPlan({required this.day, required this.items});
}

class _PlanItem {
  final String time;
  final String place;
  final String memo;

  final bool isLodging;
  final Map<String, dynamic>? transport;
  final Map<String, dynamic>? loc;
  final String? mapUrl;

  // 도착지에 보여줄 데이터
  final Map<String, dynamic>? transportFromPrev;
  final List<Map<String, dynamic>> transportOptionsFromPrev;

  // ✅ 추가: "이 아이템에서 다음 아이템"으로 넘길 보조 후보 (정렬 영향을 받지 않도록 아이템에 붙여둠)
  final List<Map<String, dynamic>>? optsFromHere;

  _PlanItem({
    required this.time,
    required this.place,
    required this.memo,
    this.isLodging = false,
    this.transport,
    this.loc,
    this.mapUrl,
    this.transportFromPrev,
    this.transportOptionsFromPrev = const [],
    this.optsFromHere, // ← 추가
  });
}

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

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.items,
    required this.editing,
    this.subtitle,
    required this.onEdit,
    required this.onDelete,
  });

  final int day;
  final List<_PlanItem> items;
  final bool editing;
  final String? subtitle;
  final void Function(int itemIndex) onEdit;
  final void Function(int itemIndex) onDelete;

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
            ...List.generate(items.length, (i) => _PlanTile(
                  item: items[i],
                  editing: editing,
                  onTap: () => onEdit(i),
                  onDelete: () => onDelete(i),
                )),
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.item,
    required this.editing,
    required this.onTap,
    required this.onDelete,
  });

  final _PlanItem item;
  final bool editing;
  final VoidCallback onTap;
  final VoidCallback onDelete;

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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.memo.isNotEmpty)
            Text(item.memo, style: TextStyle(color: Colors.grey[700])),
          if (item.isLodging)
            const Text('🏨 숙소', style: TextStyle(color: Colors.blue)),

          // ✅ 도착지 기준 이동정보 표시
          if (item.transportFromPrev != null) ...[
            const SizedBox(height: 2),
            Builder(builder: (context) {
              final primary = item.transportFromPrev!;
              // 1) 후보 풀 만들기: [primary, ...options]
              final List<Map<String, dynamic>> pool = [
                {
                  'type': (primary['type'] ?? primary['mode']),
                  'duration_min': primary['duration_min'],
                  'cost_estimate_krw': primary['cost_estimate_krw'],
                },
                ...item.transportOptionsFromPrev,
              ];

              // 2) (type, duration 5분 버킷) 기준으로 유니크 2개만 추림
              String sigOf(Map<String, dynamic> r) {
                final t = (r['type'] ?? r['mode'])?.toString() ?? '-';
                final m = (r['duration_min'] ?? 0) as num;
                final bucket = (m / 5).round() * 5;
                return '$t|$bucket';
              }

              final seen = <String>{};
              final uniq = <Map<String, dynamic>>[];
              for (final r in pool) {
                final s = sigOf(r);
                if (seen.add(s)) uniq.add(r);
                if (uniq.length == 2) break; // 최대 2개만
              }

              // 3) 출력 문자열
              String fmt(Map<String, dynamic> r) {
                final t = (r['type'] ?? r['mode'])?.toString() ?? '-';
                final m = r['duration_min'] ?? '-';
                final c = r['cost_estimate_krw'];
                return '$t ($m분${c != null ? ', 약 $c원' : ''})';
              }

              String line = '➡ 추천 이동수단: ${fmt(uniq[0])}';
              if (uniq.length > 1) line += ' · ${fmt(uniq[1])}';

              return Text(line, style: TextStyle(color: Colors.grey[800]));
            }),
          ],
        ],
      ),
      trailing: editing
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              iconSize: 26,
              color: Theme.of(context).colorScheme.error,
              onPressed: onDelete,
            )
          : null,
      onTap: editing ? onTap : null,
    );
  }
}

// ✅ Day 선택 위젯
class _DayPicker extends StatelessWidget {
  final int totalDays;
  final int initialDay;
  final ValueChanged<int> onChanged;

  const _DayPicker({
    required this.totalDays,
    required this.initialDay,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('일차 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(totalDays, (index) {
              final day = index + 1;
              final isSelected = day == initialDay;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text('Day $day'),
                  selected: isSelected,
                  onSelected: (_) => onChanged(day),
                  selectedColor: Colors.blue,
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
