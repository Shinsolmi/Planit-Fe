// lib/screens/completion_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../env.dart';
import '../root_tabs.dart';

class CompletionScreen extends StatefulWidget {
  const CompletionScreen({super.key});
  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchItinerary();
  }

  Future<List<dynamic>> _fetchItinerary() async {
    final url = Uri.parse('$baseUrl/');
    final res = await http.get(url).timeout(const Duration(seconds: 10));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);
      // 서버 응답 구조에 맞게 파싱
      if (body is List) return body;
      if (body is Map && body['data'] is List) return List.from(body['data']);
      return const [];
    } else {
      throw Exception('로드 실패: ${res.statusCode} ${res.body}');
    }
  }

  void _goHomeTab([int index = 0]) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => RootTabs(initialIndex: index)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        title: GestureDetector(
          onTap: () => _goHomeTab(0),
          child: const Text('PLANIT'),
        ),
        actions: [
          TextButton(
            onPressed: () => _goHomeTab(0), // 질문 탭으로
            child: const Text('홈으로', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('오류: ${snap.error}'));
          }
          final itinerary = snap.data ?? const [];
          if (itinerary.isEmpty) {
            return const Center(child: Text('일정 데이터가 없습니다.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: itinerary.length,
            itemBuilder: (context, index) {
              final dayPlan = (itinerary[index] as Map?) ?? const {};
              final plans = (dayPlan['plan'] as List?) ?? const [];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Day ${dayPlan["day"] ?? ""}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ...plans.map<Widget>((e) {
                        final m = (e as Map?) ?? const {};
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Text('${m['time'] ?? ''}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          title: Text('${m['place'] ?? ''}'),
                          subtitle: Text('${m['memo'] ?? ''}'),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _goHomeTab(1), // 예: 교통 탭으로 돌아가기 원하면 1
        label: const Text('탭으로 돌아가기'),
        icon: const Icon(Icons.exit_to_app),
      ),
      // ⛔ bottomNavigationBar 없음
    );
  }
}
