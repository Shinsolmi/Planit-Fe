import 'package:flutter/material.dart';
import 'package:planit/widgets/custom_app_bar.dart';
import 'transport_tip_list_screen.dart'; 

class TransportSelectionPage extends StatelessWidget {
  const TransportSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            const Text('교통수단 선택', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            
            // ✅ 택시 (기존 로직 유지)
            _tile(context, Icons.local_taxi, '택시', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransportTipListScreen(transportType: '택시')),
              );
            }),
            
            // ✅ 버스 (추가)
            _tile(context, Icons.directions_bus, '버스', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransportTipListScreen(transportType: '버스')),
              );
            }),
            
            // ✅ 지하철 (추가)
            _tile(context, Icons.subway, '지하철', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransportTipListScreen(transportType: '지하철')),
              );
            }),
            
            // ✅ 기차 (추가)
            _tile(context, Icons.train, '기차', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransportTipListScreen(transportType: '기차')),
              );
            }),
          ],
        ),
      ),
      // 하단 바 그대로 쓰면 됨
      // bottomNavigationBar: MyBottomNavBar(),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}