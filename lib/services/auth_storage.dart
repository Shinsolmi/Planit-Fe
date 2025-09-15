import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  // 저장 키
  static const _kTokenKey = 'auth_token';
  static const _kUserNameKey = 'auth_user_name';

  /// 토큰 저장
  static Future<void> saveToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kTokenKey, token);
  }

  /// 토큰 읽기 (없으면 null)
  static Future<String?> getToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kTokenKey);
  }

  /// 로그인 여부 (토큰 존재 여부로 판단)
  static Future<bool> isLoggedIn() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  /// 로그아웃 (토큰/프로필 삭제)
  static Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kTokenKey);
    await sp.remove(_kUserNameKey);
  }

  /// 유저명 저장
  static Future<void> saveUserName(String name) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUserNameKey, name);
  }

  /// 유저명 읽기 (없으면 null)
  static Future<String?> getUserName() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kUserNameKey); // ← 반환 추가
  }
}
