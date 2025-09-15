// lib/screens/completion_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:planit/services/auth_storage.dart';
import 'package:planit/widgets/custom_app_bar.dart';

import '../env.dart';
import '../root_tabs.dart';

class CompletionScreen extends StatefulWidget {
  const CompletionScreen({super.key, this.scheduleId});
  final int? scheduleId;

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen> {
  Map<String, dynamic>? _schedule;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.scheduleId != null) {
      _fetchScheduleById(widget.scheduleId!);
    } else {
      _fetchMySchedules(); // 기존 로직이 있으면 유지
    }
  }

  Future<void> _fetchScheduleById(int id) async {
    setState(() { _loading = true; _error = null; });
    try {
      final jwt = await AuthStorage.getToken();
      debugPrint('JWT? ${jwt != null && jwt.isNotEmpty}');
      final res = await http.get(
        Uri.parse('$baseUrl/schedules/$id'),
        headers: {
          'Accept': 'application/json',
          if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
        },
      );


      debugPrint('[GET /schedules/$id] status=${res.statusCode}');
      debugPrint('[GET /schedules/$id] body=${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        // JSON이 아닐 수도 있으니 방어적 파싱
        if (!(res.headers['content-type'] ?? '').contains('application/json')) {
          throw FormatException('서버가 JSON이 아닌 응답을 보냈습니다.');
        }
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _schedule = data);
      } else {
        setState(() => _error = '로드 실패: ${res.statusCode}  ${res.body}');
      }
    } catch (e) {
      setState(() => _error = '파싱/네트워크 오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 필요하면 내 일정 목록용
  Future<void> _fetchMySchedules() async {
    setState(() { _loading = true; _error = null; });
    try {
      final jwt = await AuthStorage.getToken();
      final url = Uri.parse('$baseUrl/schedules/me'); // 또는 /schedules/me/full
      final res = await http.get(url, headers: {
        'Accept': 'application/json',
        if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
      });

      debugPrint('[GET /schedules/me] status=${res.statusCode}');
      debugPrint('[GET /schedules/me] body=${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final isJson = (res.headers['content-type'] ?? '').contains('application/json');
        if (!isJson) throw const FormatException('서버가 JSON이 아닌 응답을 보냈습니다.');
        final data = jsonDecode(res.body);
        // TODO: data로 UI 갱신
      } else {
        debugPrint('로드 실패: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      setState(() => _error = '파싱/네트워크 오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }
    // _schedule 표시(또는 목록)
    return Scaffold(
      appBar: AppBar(title: const Text('내 일정')),
      body: _schedule == null
          ? const Center(child: Text('일정을 불러오지 못했습니다.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_schedule.toString()),
            ),
    );
  }
}
