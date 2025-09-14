import 'package:flutter/material.dart';

class TabsController extends InheritedWidget {
  final void Function(int) setIndex;
  const TabsController({
    super.key,
    required this.setIndex,
    required Widget child,
  }) : super(child: child);

  static TabsController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabsController>();

  @override
  bool updateShouldNotify(TabsController oldWidget) => false;
}
