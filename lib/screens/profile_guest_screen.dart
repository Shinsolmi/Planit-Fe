import 'package:flutter/material.dart';
import 'transportation_screen.dart';
import 'mypage_screen.dart';
import 'question_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/bottom_nav_bar.dart';

class ProfileGuestScreen extends StatefulWidget {
  @override
  _ProfileGuestScreenState createState() => _ProfileGuestScreenState();
}

class _ProfileGuestScreenState extends State<ProfileGuestScreen> {
  int _selectedIndex = -1; // ✅ 아무것도 선택되지 않도록 설정

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => QuestionPage()));
    } else if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => TransportSelectionPage()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => MypageScreen()));
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(), // ✅ 앱바 위젯 적용
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ✅ 지금 유용한 정보와 혜택!
                Text('지금 유용한 정보와 혜택!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      buildBenefitCard(
                        backgroundColor: Color(0xFFFFD6DC),
                        image: Icons.shopping_bag,
                        text: '일본 기념품 쇼핑은 \n돈키호테에서!',
                      ),
                      SizedBox(width: 12),
                      buildBenefitCard(
                        backgroundColor: Color(0xFFB7E3F8),
                        image: Icons.beach_access,
                        text: '갓성비 자랑하는\n중국 최고의 휴양지',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                /// ✅ 추천 카드
                Text('이런 곳 어떠세요?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      buildRecommendationCard(
                        imageUrl: 'https://via.placeholder.com/150',
                        title: '도쿄의 독특한 전문 박물관 BEST 3',
                        subtitle: '도쿄',
                        profileLabel: '곰돌이',
                      ),
                      SizedBox(width: 12),
                      buildRecommendationCard(
                        imageUrl: 'https://via.placeholder.com/150',
                        title: "'천안문문' 리뷰",
                        subtitle: '베이징',
                        profileLabel: '여행자',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  /// ✅ 혜택 카드 위젯
  Widget buildBenefitCard({
    required Color backgroundColor,
    required IconData image,
    required String text,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(image, size: 40),
          SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// ✅ 추천 카드 위젯
  Widget buildRecommendationCard({
    required String imageUrl,
    required String title,
    required String subtitle,
    required String profileLabel,
  }) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 10, backgroundColor: Colors.white),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    profileLabel,
                    style: TextStyle(fontSize: 10, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Spacer(),
            Text(
              title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
