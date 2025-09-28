import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:planit/env.dart';
import 'package:planit/widgets/custom_app_bar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.query});
  final String query;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final WebViewController _controller;
  late final TextEditingController _searchController;
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(_buildUrl(widget.query)));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _buildUrl(String query) {
    // 쿼리 매개변수가 없을 경우 기본 URL 반환
    if (query.isEmpty) {
      return '$baseUrl/placemap';
    }
    return '$baseUrl/placemap?q=${Uri.encodeComponent(query)}';
  }

  void _onSearch(String query) {
    if (query.isNotEmpty) {
      _controller.loadRequest(Uri.parse(_buildUrl(query)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              // ✅ 홈 화면과 동일한 스타일 적용 (Prefix Icon 사용)
              decoration: const InputDecoration(
                hintText: '장소 이름을 입력하세요',
                prefixIcon: Icon(Icons.search), // 홈 화면처럼 Prefix Icon 사용
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              onSubmitted: _onSearch, // 기능은 WebView를 리로드하도록 유지
            ),
          ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}