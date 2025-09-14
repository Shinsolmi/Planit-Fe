import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planit/main.dart'; // 프로젝트 이름으로 변경 필요

void main() {
  testWidgets('PLANIT 앱 UI 요소가 올바르게 표시되는지 테스트', (WidgetTester tester) async {
    // 앱 실행
    await tester.pumpWidget(MyApp());

    // PLANIT 텍스트 확인
    expect(find.text('PLANIT'), findsOneWidget);

    // 로그인 안내 문구 확인
    expect(find.text('로그인이 필요합니다.'), findsOneWidget);

    // 로그인 버튼 확인
    expect(find.text('로그인'), findsOneWidget);

    // 주요 메뉴 항목 확인
    expect(find.text('예정된 일정'), findsOneWidget);
    expect(find.text('지난 일정 관리'), findsOneWidget);
    expect(find.text('저장한 대중교통 팁'), findsOneWidget);
    expect(find.text('작성한 후기'), findsOneWidget);

    // BottomNavigationBar 아이콘 확인 (예: Calendar 아이콘)
    expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    expect(find.byIcon(Icons.article), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });
}
