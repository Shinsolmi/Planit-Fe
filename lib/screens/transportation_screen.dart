import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'mypage_screen.dart';
import 'question_screen.dart';
import 'profile_guest_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import 'transport_tip_detail_screen.dart';
import '../env.dart';

class TransportSelectionPage extends StatefulWidget {
  const TransportSelectionPage({super.key});
  @override
  State<TransportSelectionPage> createState() => _TransportSelectionPageState();
}

class _TransportSelectionPageState extends State<TransportSelectionPage> {
  final List<Map<String, Object>> transportOptions = const [
    {'icon': Icons.local_taxi,     'label': '택시'},
    {'icon': Icons.directions_bus, 'label': '버스'},
    {'icon': Icons.subway,         'label': '지하철'},
    {'icon': Icons.train,          'label': '기차'},
  ];

  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => QuestionPage()), 
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MypageScreen()), 
        );
        break;
      default:
        break;
    }
  }

  Future<void> _openTipDetail(String transport) async {
    try {
      final url = Uri.parse('$baseUrl/transport-tips?type=${Uri.encodeQueryComponent(transport)}');
      final res = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final tipText = data['tip'] as String? ?? '팁이 없습니다.';
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransportTipDetailScreen(transportType: transport, tip: tipText),
          ),
        );
      } else {
        _showError('불러오기 실패: ${res.statusCode}');
      }
    } catch (e) {
      _showError('에러 발생: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: transportOptions.length + 1,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          if (i == 0) {
            return const Text('교통수단 선택', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
          }
          final option = transportOptions[i - 1];
          final icon  = option['icon'] as IconData;
          final label = option['label'] as String;

          return ListTile(
            leading: Icon(icon, size: 30),
            title: Text(label, style: const TextStyle(fontSize: 18)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _openTipDetail(label),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
