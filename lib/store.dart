import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api.dart';


class AcademyStore extends ChangeNotifier {
  final AcademyApi api;
  AcademyStore(this.api);

  Map<String,dynamic>? user;
  List<Map<String,dynamic>> categories=[];
  List<Map<String,dynamic>> latest=[];
  List<Map<String,dynamic>> continuing=[];
  Future<void> Function()? beforeSignOut;
  bool busy=false;
  String? error;
  int _sessionVersion=0;

  bool get signedIn=>user!=null;
  bool get active=>user?['subscription'] is Map && user!['subscription']['active']==true;

  Future<void> initialize() async {
    busy=true;
    notifyListeners();
    try {
      await api.initialize();
      await reload();
    } catch(e) {
      busy=false;
      error=e.toString();
      notifyListeners();
    }
  }

  Future<void> reload({bool preserveAuthOnTemporaryFailure=false}) async {
    final version=_sessionVersion;
    busy=true;
    error=null;
    notifyListeners();
    try {
      final r=await api.bootstrap();
      if(version!=_sessionVersion)return; // Discard stale logout/login requests.
      final received=r['user'] is Map?Map<String,dynamic>.from(r['user']):null;
      if(api.token!=null && received!=null) {
        user=received;
      }else if(api.token!=null) {
        // Anonymous bootstrap responses can be cached. Verify before clearing login.
        try {
          final verified=await api.me();
          if(version!=_sessionVersion)return;
          user=verified;
        }on ApiError catch(e){
          if(version!=_sessionVersion)return;
          if(e.status==401){
            await api.clearToken();
            user=null;
          }else if(!preserveAuthOnTemporaryFailure){rethrow;}
        }
      }else {
        user=null;
      }
      if(version!=_sessionVersion)return;
      categories=_mapList(r['categories']);
      latest=_mapList(r['latest_lessons']);
      continuing=_mapList(r['continue']);
    }catch(e){
      if(version==_sessionVersion)error=e.toString();
    }finally{
      if(version==_sessionVersion){
        busy=false;
        notifyListeners();
      }
    }
  }

  Future<void> login(String email,String password) async {
    final data=await api.login(email,password);
    final token=data['token']?.toString()??'';
    if(token.length!=64 || data['user'] is! Map){
      throw const ApiError('Sunucu giriş yanıtı eksik.');
    }
    await api.saveToken(token);
    _sessionVersion++;
    user=Map<String,dynamic>.from(data['user']);
    error=null;
    busy=false;
    notifyListeners();
    unawaited(reload(preserveAuthOnTemporaryFailure:true));
  }

  Future<void> register(Map<String,dynamic> input) async {
    final data=await api.register(input);
    final token=data['token']?.toString()??'';
    if(token.length!=64 || data['user'] is! Map){
      throw const ApiError('Sunucu kayıt yanıtı eksik.');
    }
    await api.saveToken(token);
    _sessionVersion++;
    user=Map<String,dynamic>.from(data['user']);
    error=null;
    busy=false;
    notifyListeners();
    unawaited(reload(preserveAuthOnTemporaryFailure:true));
  }

  Future<void> logout() async {
    // Update UI instantly; never hold the Profile tab on a network request.
    _sessionVersion++;
    user=null;
    continuing=[];
    error=null;
    busy=false;
    notifyListeners();
    try{await beforeSignOut?.call();}catch(_){}
    await api.logout(); // Clears secure storage before attempting remote revoke.
    unawaited(reload(preserveAuthOnTemporaryFailure:true));
  }

  void refreshUser(Map<String,dynamic> u){user=u;notifyListeners();}
  @override void dispose(){api.dispose();super.dispose();}
}
List<Map<String,dynamic>> _mapList(dynamic data)=>
  data is List?data.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList():[];
