import 'package:flutter/material.dart';
import '../tabs_controller.dart';
import '../root_tabs.dart';
import '../root_tabs.dart' show kTabHome; // 상수 사용

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title = 'PLANIT',
    this.actions,
    this.showBack = false,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _goHomeTabOrRoot(BuildContext context) {
    final ctrl = TabsController.of(context);
    if (ctrl != null) {
      // ✅ RootTabs 안: 탭 인덱스만 변경
      ctrl.setIndex(kTabHome);
    } else {
      // ✅ RootTabs 밖(Login/Signup 등): 루트로 복귀
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RootTabs(initialIndex: kTabHome)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBack,
      centerTitle: false,        // ← 왼쪽 정렬
      titleSpacing: 16,          // ← 좌측 여백
      backgroundColor: Colors.white,
      foregroundColor: Colors.blue,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      actions: actions,
    );
  }
}
