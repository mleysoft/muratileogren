import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiError implements Exception {
  final String message;
  final int status;
  const ApiError(this.message, [this.status = 0]);
  @override
  String toString() => message;
}

class AcademyApi {
  final http.Client _client;
  final FlutterSecureStorage _storage;
  AcademyApi({http.Client? client, FlutterSecureStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );
  String? _token;
  String? get token => _token;
  String get root => AppConfig.api;
  Future<void> initialize() async {
    _token = await _storage.read(key: 'mg_mobile_token');
  }
  Future<void> saveToken(String token) async {
    _token = token;
    await _storage.write(key: 'mg_mobile_token', value: token);
  }
  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: 'mg_mobile_token');
  }
  Future<dynamic> request(String method, String path, {Map<String, dynamic>? json}) async {
    final uri = Uri.parse('$root/$path');
    final req = http.Request(method, uri)
      ..headers.addAll({'Accept': 'application/json', 'Content-Type': 'application/json', 'Cache-Control':'no-store', 'Pragma':'no-cache'});
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
    if (json != null) req.body = jsonEncode(json);
    try {
      final streamed = await _client.send(req).timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamed);
      dynamic parsed;
      try { parsed = jsonDecode(utf8.decode(response.bodyBytes)); }
      catch (_) { throw ApiError('Sunucudan beklenmeyen yanıt geldi.', response.statusCode); }
      if (parsed is! Map || parsed['ok'] != true) {
        final error = parsed is Map ? parsed['error'] : null;
        final msg = error is Map ? error['message']?.toString() : null;
        throw ApiError(msg ?? 'İşlem gerçekleştirilemedi.', response.statusCode);
      }
      return parsed['data'];
    } on TimeoutException {
      throw const ApiError('Bağlantı zaman aşımına uğradı.');
    } on ApiError { rethrow; }
    catch (_) { throw const ApiError('İnternet bağlantısını veya sunucu adresini kontrol et.'); }
  }
  Future<Map<String, dynamic>> bootstrap() async => Map<String, dynamic>.from(await request('GET', 'bootstrap'));
  Future<Map<String, dynamic>> category(int id) async => Map<String, dynamic>.from(await request('GET', 'categories/$id'));
  Future<Map<String, dynamic>> lesson(int id) async => Map<String, dynamic>.from(await request('GET', 'lessons/$id'));
  Future<List<dynamic>> search(String term) async => List<dynamic>.from(await request('GET', 'lessons?q=${Uri.encodeQueryComponent(term)}'));
  Future<List<dynamic>> plans() async => List<dynamic>.from(await request('GET', 'plans'));
  Future<List<dynamic>> progress() async => List<dynamic>.from(await request('GET', 'me/progress'));
  Future<List<dynamic>> payments() async => List<dynamic>.from(await request('GET', 'me/payments'));
  Future<Map<String, dynamic>> me() async => Map<String, dynamic>.from(await request('GET', 'me'));
  Future<Map<String, dynamic>> login(String email, String password) async => Map<String, dynamic>.from(
      await request('POST', 'auth/login', json: {'email': email, 'password': password, 'device': 'Flutter Mobile'}));
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async => Map<String, dynamic>.from(
      await request('POST', 'auth/register', json: {...data, 'device': 'Flutter Mobile'}));
  // Revoke the exact old token, independently of subsequent sign-ins.
  Future<void> revokeToken(String token) async {
    final client=http.Client();
    try {
      final request=http.Request('POST',Uri.parse('$root/auth/logout'))
        ..headers.addAll({
          'Accept':'application/json',
          'Content-Type':'application/json',
          'Authorization':'Bearer $token',
          'Cache-Control':'no-store',
        })
        ..body='{}';
      final response=await client.send(request).timeout(const Duration(seconds:8));
      await response.stream.drain<void>();
    }catch(_) {
      // Remote logout is best-effort. Local credentials are already cleared.
    }finally {client.close();}
  }
  Future<void> logout() async {
    final oldToken=_token;
    await clearToken();
    if(oldToken!=null && oldToken.isNotEmpty){
      unawaited(revokeToken(oldToken));
    }
  }
  Future<Map<String, dynamic>> updateProfile(String name, String phone) async => Map<String, dynamic>.from(
      await request('PATCH', 'me/profile',json:{'name':name,'phone':phone}));
  Future<void> updateMarketing(bool enabled) async {await request('PATCH','me/marketing',json:{'enabled':enabled});}
  Future<void> deleteAccount(String password) async {await request('POST','me/delete',json:{'password':password});await clearToken();}
  Future<Map<String, dynamic>> updateProgress(int lessonId, int pos, int duration) async => Map<String, dynamic>.from(
      await request('POST','lessons/$lessonId/progress',json:{'position_sec':pos,'duration_sec':duration}));
  Future<Map<String, dynamic>> rate(int lessonId, int stars) async => Map<String, dynamic>.from(
      await request('POST','lessons/$lessonId/rating',json:{'stars':stars}));
  Uri videoUri(int lessonId) => Uri.parse('$root/stream.php?lesson=$lessonId');
  Uri attachmentUri(int lessonId) => Uri.parse('$root/file.php?lesson=$lessonId');
  Map<String,String> get authHeaders => {'Authorization':'Bearer ${_token ?? ''}'};
  Future<List<int>> download(int lessonId) async {
    final req=http.Request('GET',attachmentUri(lessonId))..headers.addAll(authHeaders);
    final res=await _client.send(req).timeout(const Duration(minutes: 2));
    if(res.statusCode!=200) throw ApiError('Ders dosyası indirilemedi.',res.statusCode);
    final bytes=<int>[];
    await for(final chunk in res.stream) {
      bytes.addAll(chunk);
      if(bytes.length>200*1024*1024) throw const ApiError('Dosya boyutu sınırı aşıldı.');
    }
    return bytes;
  }
  void dispose() => _client.close();
}
