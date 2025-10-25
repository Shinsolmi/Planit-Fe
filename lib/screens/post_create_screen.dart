// lib/screens/post_create_screen.dart (수정된 전체 코드)
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // ✅ image_picker 임포트
import '../env.dart';
import '../services/auth_storage.dart';
import '../widgets/custom_app_bar.dart'; 

class PostCreateScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData; 
  
  const PostCreateScreen({super.key, this.initialData});

  @override
  State<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedCategory;
  bool _isSaving = false;
  
  bool get isEditing => widget.initialData != null; 
  int? get postId => widget.initialData?['post_id'];
  
  final List<String> _categories = ['맛집', '행사', '사건', '핫플', '기타'];
  
  // ✅ XFile 경로를 저장할 리스트로 변경 (이미지 URL 대신)
  final List<XFile> _attachedImages = []; 
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // ✅ 수정 모드 초기화 로직 유지
    if (isEditing) {
      _titleController.text = widget.initialData!['post_title'] ?? '';
      _contentController.text = widget.initialData!['content'] ?? '';
      _selectedCategory = widget.initialData!['category'] ?? _categories.first;
      
      // 수정 시 기존 이미지 URL을 XFile로 변환할 수 없으므로, 현재는 비워둡니다.
      // (실제 앱에서는 ImageUrl과 FilePath를 별도로 관리해야 함)
      // _attachedImages.addAll(mediaList.map((m) => XFile(m['media_url'].toString()))); 
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ✅ 이미지 선택 기능 구현
  Future<void> _pickImages() async {
    if (_attachedImages.length >= 5) {
      _showSnack('사진은 최대 5장까지 첨부할 수 있습니다.');
      return;
    }
    
    // 갤러리에서 여러 이미지 선택
    final List<XFile> selectedImages = await _picker.pickMultiImage();

    if (selectedImages.isNotEmpty) {
      setState(() {
        // 기존 이미지와 새로 선택한 이미지를 합쳐 5장까지만 유지
        _attachedImages.addAll(selectedImages.take(5 - _attachedImages.length));
      });
    }
  }

  // ✅ 글 등록/수정 API 호출 (다중 파일 업로드 로직으로 변환 필요)
  Future<void> _submitPost() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      _showSnack('제목과 내용을 모두 입력해 주세요.');
      return;
    }
    if (_selectedCategory == null) {
      _showSnack('카테고리를 반드시 선택해 주세요.');
      return;
    }

    setState(() => _isSaving = true);
    

    
    try {
      // 1. API 요청 로직 (Multi-Part Form Data 사용)
      final token = await AuthStorage.getToken();
      final uri = isEditing 
          ? Uri.parse('$baseUrl/community/$postId') 
          : Uri.parse('$baseUrl/community'); 

      final request = isEditing ? http.MultipartRequest('PUT', uri) : http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      
      // 2. 텍스트 필드 데이터 추가
      request.fields['post_title'] = _titleController.text;
      request.fields['content'] = _contentController.text;
      request.fields['category'] = _selectedCategory!;
      
      // 3. 이미지 파일 첨부
      for (var file in _attachedImages) {
        request.files.add(await http.MultipartFile.fromPath('images', file.path));
      }
      
      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);


      if (!mounted) return;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        _showSnack(isEditing ? '게시글이 성공적으로 수정되었습니다.' : '게시글이 성공적으로 등록되었습니다.');
        Navigator.pop(context, true); 
      } else if (res.statusCode == 403) {
         _showSnack('수정 권한이 없습니다.');
      } else {
        _showSnack('처리 실패: ${res.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('네트워크 오류: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '글 수정' : '새 글 작성'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _submitPost,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isEditing ? '수정 완료' : '등록', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 카테고리 선택 (필수)
            const Text('카테고리 선택 (필수)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                children: _categories.map((cat) => ChoiceChip(
                  label: Text(cat),
                  selected: _selectedCategory == cat,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? cat : null;
                    });
                  },
                  selectedColor: Colors.blue,
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(
                    color: _selectedCategory == cat ? Colors.white : Colors.black,
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // 2. 제목 입력
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 16),

            // 3. 내용 입력
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: '내용을 작성해주세요.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              minLines: 5,
            ),
            const SizedBox(height: 20),

            // 4. 사진 첨부 (다중 첨부 기능)
            const Text('사진 첨부', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Row(
              children: [
                // 사진 추가 버튼
                InkWell(
                  onTap: _pickImages, // ✅ 실제 이미지 피커 호출
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt, color: Colors.grey),
                        Text('${_attachedImages.length}/5', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 첨부된 사진 미리보기 목록
                Expanded(
                  child: SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _attachedImages.length,
                      itemBuilder: (context, index) {
                        final XFile imageFile = _attachedImages[index];

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Stack(
                            children: [
                              // ✅ 실제 선택된 이미지를 표시
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(imageFile.path), // File 위젯 사용
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // 삭제 버튼
                              Positioned(
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _attachedImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 18, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}