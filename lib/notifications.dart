import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api.dart';
import 'store.dart';
import 'theme.dart';
import 'lesson.dart';

/// Only creates a push registration while a validated mobile session exists.
/// If Firebase platform files are not installed, the rest of the app still works.
class AcademyNotifications extends ChangeNotifier with WidgetsBindingObserver {
  final AcademyStore store;
  AcademyNotifications(this.store) {store.addListener(_authChanged);WidgetsBinding.instance.addObserver(this);}
  bool _configured=false, _loading=false, _wasSignedIn=false;
  StreamSubscription<String>? _tokenStream;
  StreamSubscription<RemoteMessage>? _foregroundStream;
  int unread=0;
  List<Map<String,dynamic>> items=[];
  String? setupError;

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      _configured=true;
      _tokenStream=FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        if(store.signedIn) _register(token);
      });
      _foregroundStream=FirebaseMessaging.onMessage.listen((event){
        if(store.signedIn) refresh();
      });
      FirebaseMessaging.onMessageOpenedApp.listen((event){if(store.signedIn)refresh();});
      _authChanged();
    } catch(e) {
      setupError='Firebase yapılandırması eksik: ${e.toString()}';
      // No crash. The in-app notification inbox still uses the PHP API.
      _authChanged();
    }
  }

  @override void didChangeAppLifecycleState(AppLifecycleState state){
    if(state==AppLifecycleState.resumed && store.signedIn){refresh();if(_configured)registerDevice();}
  }
  void _authChanged() {
    final signedIn=store.signedIn;
    if(!signedIn){
      if(_wasSignedIn){unread=0;items=[];notifyListeners();}
      _wasSignedIn=false;
      return;
    }
    if(!_wasSignedIn){
      _wasSignedIn=true;
      refresh();
      if(_configured) registerDevice();
    }
  }

  Future<void> registerDevice() async {
    if(!_configured||!store.signedIn)return;
    try {
      final permission=await FirebaseMessaging.instance.requestPermission(
        alert:true,badge:true,sound:true);
      if(permission.authorizationStatus==AuthorizationStatus.denied)return;
      if(Platform.isIOS){
        String? apns;
        for(var i=0;i<8&&apns==null&&store.signedIn;i++){
          apns=await FirebaseMessaging.instance.getAPNSToken();
          if(apns==null) await Future<void>.delayed(const Duration(seconds:2));
        }
        if(apns==null)return;
      }
      final token=await FirebaseMessaging.instance.getToken();
      if(token!=null&&store.signedIn)await _register(token);
    }catch(e){setupError='Bildirim kaydı: $e';notifyListeners();}
  }
  Future<void> _register(String token) async {
    if(!store.signedIn)return;
    try{await store.api.registerPush(token,Platform.isIOS?'ios':'android');}catch(_){/* Retry on sign-in/restart. */}
  }
  Future<void> beforeLogout() async {
    try {await store.api.unregisterPush().timeout(const Duration(seconds:5));} catch (_) {}
    if(_configured){
      try{await FirebaseMessaging.instance.deleteToken();}catch(_){}
    }
    unread=0;items=[];_wasSignedIn=false;notifyListeners();
  }
  Future<void> refresh()async{
    if(!store.signedIn||_loading)return;
    _loading=true;
    try {
      final r=await store.api.notifications();
      if(store.signedIn){
        items=(r['items'] as List? ?? []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
        unread=(r['unread'] as num?)?.toInt()??0;
        notifyListeners();
      }
    }catch(_){}finally{_loading=false;}
  }
  Future<void> read(int id)async{
    if(!store.signedIn)return;
    try{await store.api.markNotificationRead(id);}catch(_){}
    await refresh();
  }
  @override void dispose(){WidgetsBinding.instance.removeObserver(this);_tokenStream?.cancel();_foregroundStream?.cancel();store.removeListener(_authChanged);super.dispose();}
}

class NotificationsScreen extends StatefulWidget {
  final AcademyNotifications notifications;
  final AcademyStore store;
  const NotificationsScreen({super.key,required this.notifications,required this.store});
  @override State<NotificationsScreen> createState()=>_NotificationsScreenState();
}
class _NotificationsScreenState extends State<NotificationsScreen>{
  @override void initState(){super.initState();widget.notifications.refresh();}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Bildirimler',style:TextStyle(fontWeight:FontWeight.w800))),
    body:AnimatedBuilder(animation:widget.notifications,builder:(context,_){
      final n=widget.notifications;
      if(!widget.store.signedIn)return const Center(child:Text('Bildirimleri görmek için giriş yap.'));
      if(n.items.isEmpty)return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Icon(Icons.notifications_none_rounded,size:58,color:forest),const SizedBox(height:12),
        const Text('Henüz bildirimin yok'),const SizedBox(height:10),
        TextButton(onPressed:n.refresh,child:const Text('Yenile'))]));
      return RefreshIndicator(onRefresh:n.refresh,child:ListView.separated(
        padding:const EdgeInsets.all(18),itemCount:n.items.length,
        separatorBuilder:(_,__)=>const SizedBox(height:9),
        itemBuilder:(context,i){
          final item=n.items[i];
          final isNew=item['read_at']==null;
          final kind=item['kind']?.toString()??'';
          final id=int.tryParse('${item['id']}')??0;
          final lessonId=int.tryParse('${item['lesson_id']}')??0;
          return Material(color:isNew?const Color(0xFFF0F7E9):Colors.white,borderRadius:BorderRadius.circular(18),
            child:InkWell(borderRadius:BorderRadius.circular(18),onTap:()async{
              await n.read(id);
              if(context.mounted && lessonId>0){
                Navigator.push(context,MaterialPageRoute(builder:(_)=>LessonScreen(store:widget.store,id:lessonId)));
              }
            },child:Padding(padding:const EdgeInsets.all(16),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Icon(kind=='lesson'?Icons.menu_book_rounded:kind=='resume'?Icons.play_circle_outline:Icons.notifications_outlined,color:forest),
              const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(item['title']?.toString()??'',style:TextStyle(fontWeight:isNew?FontWeight.w900:FontWeight.w700)),
                const SizedBox(height:6),Text(item['body']?.toString()??'',style:const TextStyle(color:muted,height:1.4)),
                const SizedBox(height:8),Text(item['created_at']?.toString()??'',style:const TextStyle(color:muted,fontSize:11)),
              ])),if(isNew)Container(width:8,height:8,decoration:const BoxDecoration(color:Colors.red,shape:BoxShape.circle))
            ]))));
        }));
    }));
}
