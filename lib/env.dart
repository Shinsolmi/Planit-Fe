import 'package:flutter/foundation.dart' show kIsWeb;

const String _envBase = String.fromEnvironment('BASE_URL', defaultValue: '');

const bool useTunnel =true; //false면 로컬
const _tunnel = 'https://46ca8e82acd5.ngrok-free.app';


const _local  = 'http://10.0.2.2:3000';
String get baseUrl => _envBase.isNotEmpty ? _envBase : (useTunnel ? _tunnel : _local);

String get webBaseUrl => baseUrl;
const String mapPagePath = '/map?ngrok-skip-browser-warning=true';         // 서버 라우트 (/map)