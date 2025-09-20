import 'package:flutter/foundation.dart' show kIsWeb;

const String _envBase = String.fromEnvironment('BASE_URL', defaultValue: '');

const bool useTunnel = true; // false면 로컬
const _tunnel = 'https://f2c240b71ba9.ngrok-free.app';
const _local  = 'http://10.0.2.2:3000';
String get baseUrl => _envBase.isNotEmpty ? _envBase : (useTunnel ? _tunnel : _local);
