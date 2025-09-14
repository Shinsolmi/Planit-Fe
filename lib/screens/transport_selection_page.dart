import 'package:flutter/material.dart';
import 'package:planit/widgets/custom_app_bar.dart';

class TransportSelectionPage extends StatelessWidget {
  const TransportSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SafeArea(
        child: ListView(
          // 필요하면 이 정도만 패딩
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            const Text('교통수단 선택', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _tile(context, Icons.local_taxi, '택시', onTap: () {/* TODO */}),
            _tile(context, Icons.directions_bus, '버스', onTap: () {/* TODO */}),
            _tile(context, Icons.subway, '지하철', onTap: () {/* TODO */}),
            _tile(context, Icons.train, '기차', onTap: () {/* TODO */}),
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
