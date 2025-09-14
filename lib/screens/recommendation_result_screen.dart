import 'package:flutter/material.dart';
import 'package:planit/widgets/custom_app_bar.dart';

class RecommendationResultPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// ✅ AppBar 타이틀 클릭 시 마이페이지 이동
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('추천 일정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Container(
              height: 200,
              color: Colors.grey[300],
              child: Center(child: Text('지도 API 예시 (예: Kakao 또는 Google Maps)')),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(onPressed: () {}, child: Text('내 일정으로 담기')),
                SizedBox(width: 10),
                OutlinedButton(onPressed: () {}, child: Text('다시 추천받기')),
              ],
            )
          ],
        ),
      ),
    );
  }
}