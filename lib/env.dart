import 'package:flutter/foundation.dart' show kIsWeb;

const String _envBase = String.fromEnvironment('BASE_URL', defaultValue: '');

String get baseUrl =>
    _envBase.isNotEmpty ? _envBase : (kIsWeb ? 'https://0f8d907f90ba.ngrok-free.app' : 'http://10.0.2.2:3000');
