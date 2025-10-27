import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'question3_screen.dart';
import '../widgets/custom_app_bar.dart'; // ✅ 공통 AppBar
import '../env.dart';
import '../services/auth_storage.dart';

class Question2Screen extends StatefulWidget {
  const Question2Screen({super.key});
  @override
  _Question2ScreenState createState() => _Question2ScreenState();
}

class _Question2ScreenState extends State<Question2Screen> {
  DateTime? _start; // 출발일
  DateTime? _end;   // 도착일
  bool _loading = false;

  String _fmtYMD(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  int? get _days {
    if (_start == null || _end == null) return null;
    final diff = _end!.difference(_start!).inDays + 1; // 시작/끝 포함
    return diff > 0 ? diff : null;
  }

  int? get _nights => (_days != null) ? _days! - 1 : null;

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_start ?? now) : (_end ?? _start ?? now);
    final first = now.subtract(const Duration(days: 365));
    final last = now.add(const Duration(days: 365 * 2));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _start = picked;
        if (_end != null && _end!.isBefore(_start!)) _end = _start;
      } else {
        _end = picked;
        if (_start != null && _end!.isBefore(_start!)) _start = _end;
      }
    });
  }

  Future<void> _saveDatesAndNext() async {
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('출발일과 복귀일일을 선택해 주세요.')));
      return;
    }
    final startStr = _fmtYMD(_start!);
    final endStr = _fmtYMD(_end!);
    final duration = _days; // 일수 (예: 3박4일이면 4)

    setState(() => _loading = true);
    try {
      // 1) 날짜 저장
      debugPrint('➡️ Q2 POST /ai/save-dates {startdate:$startStr, enddate:$endStr}');
      final res1 = await http.post(
        Uri.parse('$baseUrl/ai/save-dates'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'startdate': startStr, 'enddate': endStr}),
      );
      debugPrint('⬅️ /ai/save-dates status=${res1.statusCode} body=${res1.body}');

      if (res1.statusCode < 200 || res1.statusCode >= 300) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('날짜 저장 실패: ${res1.statusCode}')),
        );
        return;
      }

      // 2) (옵션) 기간도 함께 저장 — 기존 백엔드 호환용
      if (duration != null) {
        debugPrint('➡️ Q2 POST /ai/save-duration {duration:$duration}');
        final res2 = await http.post(
          Uri.parse('$baseUrl/ai/save-duration'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'duration': duration}), // 숫자 일수로 전달
        );
        debugPrint('⬅️ /ai/save-duration status=${res2.statusCode} body=${res2.body}');
        // 실패해도 치명적이지 않으니 경고만
        if (res2.statusCode < 200 || res2.statusCode >= 300) {
          debugPrint('WARN: save-duration 실패(무시 가능)');
        }
      }

      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Question3Screen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('네트워크 오류: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startLabel = _start != null ? "출발: ${_fmtYMD(_start!)}" : "출발일 선택";
    final endLabel = _end != null ? "도착: ${_fmtYMD(_end!)}" : "복귀일 선택";
    final desc = (_nights != null && _days != null)
        ? "${_nights}박 ${_days}일"
        : "여행 기간을 선택해 주세요";

    return Scaffold(
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: const [
                  Text('(2/5)', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('언제 떠나시나요?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 24),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text(startLabel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: false),
                    child: Text(endLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                desc,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveDatesAndNext,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: const Text('다음', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
            if (_loading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
