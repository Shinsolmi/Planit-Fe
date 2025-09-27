// lib/screens/transport_tip_list_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../widgets/custom_app_bar.dart';
import 'transport_tip_detail_screen.dart';

class TransportTipListScreen extends StatefulWidget {
  final String transportType;
  final String country;

  const TransportTipListScreen({
    super.key,
    required this.transportType,
    this.country = '일본', // 기본값 설정
  });

  @override
  State<TransportTipListScreen> createState() => _TransportTipListScreenState();
}

class _TransportTipListScreenState extends State<TransportTipListScreen> {
  List<dynamic> _tips = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTips();
  }

  Future<void> _fetchTips() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/tips?type=${widget.transportType}&country=${widget.country}'),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List<dynamic> fetchedTips = jsonDecode(res.body);
        setState(() {
          _tips = fetchedTips;
          _loading = false;
        });
      } else {
        setState(() {
          _error = '팁을 불러오는 데 실패했습니다.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '네트워크 오류가 발생했습니다.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _tips.isEmpty
                  ? const Center(child: Text('관련 팁이 없습니다.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tips.length,
                      itemBuilder: (context, index) {
                        final tip = _tips[index];
                        final String imageUrl = tip['image_url'] ?? '';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                : const SizedBox(width: 60, height: 60),
                            title: Text(tip['title'] ?? ''),
                            subtitle: Text(tip['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransportTipDetailScreen(tip: tip),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}