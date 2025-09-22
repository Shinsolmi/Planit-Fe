import 'package:flutter/foundation.dart' show kIsWeb;

const String _envBase = String.fromEnvironment('BASE_URL', defaultValue: '');

const _forced = 'http://10.0.2.2:3000'; 
String get baseUrl => _envBase.isNotEmpty ? _envBase : _forced;