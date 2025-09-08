import 'package:flutter/foundation.dart' show kIsWeb;

const String _envBase = String.fromEnvironment('BASE_URL', defaultValue: '');

String get baseUrl =>
    _envBase.isNotEmpty ? _envBase : (kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000');
