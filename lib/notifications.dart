import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'api.dart';
import 'store.dart';
import 'theme.dart';
import 'lesson.dart';

/// Handles authenticated push registration, inbox state and FCM deep links.
/// The backend remains the source of truth for the unread count.
class AcademyNotifications extends ChangeNotifier with WidgetsBindingObserver {
  final AcademyStore store;
  AcademyNotifications(this.store) {
    store.addListener(_authChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  bool _configured = false;
  Future<void>? _refreshTask;
  bool _wasSignedIn = false;
  int _generation = 0;
  StreamSubscription<String>? _tokenStream;
  StreamSubscription<RemoteMessage>? _foregroundStream;
  StreamSubscription<RemoteMessage>? _openedStream;
  int unread = 0;
  List<Map<String,dynamic>> items = [];
  String? setupError;
  Map<String,dynamic>? _pendingOpen;

  /// Shell consumes one event; a terminated app can receive this before UI exists.
  Map<String,dynamic>? takePendingOpen() {
    if (!store.signedIn) return null;
    final value = _pendingOpen;
    _pendingOpen = null;
    return value;
  }

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      _configured = true;
      if (Platform.isIOS) {
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true, badge: true, sound: true,
        );
      }
      _tokenStream = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        if (store.signedIn) unawaited(_register(token));
      });
      _foregroundStream = FirebaseMessaging.onMessage.listen((message) {
        if (store.signedIn) unawaited(refresh());
      });
      _openedStream = FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _onOpened(initial);
      _authChanged();
    } catch(e) {
      setupError = 'Firebase yapılandırması eksik: $e';
      _authChanged();
    }
  }

  void _onOpened(RemoteMessage message) {
    final data = message.data;
    final notificationId = int.tryParse('${data['notification_id'] ?? ''}') ?? 0;
    final lessonId = int.tryParse('${data['lesson_id'] ?? ''}') ?? 0;
    if (notificationId <= 0 && lessonId <= 0) return;
    if (!store.signedIn && store.api.token == null && !store.busy) return;
    // Never navigate into a previous user's inbox while logged out.
    // An initial notification waits until secure token bootstrap completes.
    _pendingOpen = {
      'notification_id': notificationId,
      'lesson_id': lessonId,
      'kind': '${data['kind'] ?? ''}',
    };
    notifyListeners();
  }

  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && store.signedIn) {
      unawaited(refresh());
      if (_configured) unawaited(registerDevice());
    }
  }

  void _authChanged() {
    final signedIn = store.signedIn;
    if (!signedIn) {
      if (_wasSignedIn) {
        ++_generation;
        _pendingOpen = null;
        unread = 0;
        items = [];
        unawaited(_setBadge(0));
        notifyListeners();
      }
      _wasSignedIn = false;
      return;
    }
    if (!_wasSignedIn) {
      _wasSignedIn = true;
      unawaited(refresh());
      if (_configured) unawaited(registerDevice());
      notifyListeners();
    }
  }

  Future<void> _setBadge(int count) async {
    try { await AppBadgePlus.updateBadge(count.clamp(0, 999).toInt()); } catch (_) {}
  }

  Future<void> registerDevice() async {
    if (!_configured || !store.signedIn) return;
    try {
      final permission = await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (permission.authorizationStatus == AuthorizationStatus.denied) return;
      if (Platform.isIOS) {
        String? apns;
        for (var i=0; i<8 && apns==null && store.signedIn; i++) {
          apns = await FirebaseMessaging.instance.getAPNSToken();
          if (apns==null) await Future<void>.delayed(const Duration(seconds:2));
        }
        if (apns==null) return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && store.signedIn) await _register(token);
    } catch(e) {
      setupError = 'Bildirim kaydı: $e';
      notifyListeners();
    }
  }

  Future<void> _register(String token) async {
    if (!store.signedIn) return;
    try { await store.api.registerPush(token, Platform.isIOS ? 'ios' : 'android'); } catch (_) {}
  }

  Future<void> beforeLogout() async {
    // api.token is still available while the store invokes this hook.
    try { await store.api.unregisterPush().timeout(const Duration(seconds:5)); } catch (_) {}
    if (_configured) {
      try { await FirebaseMessaging.instance.deleteToken(); } catch (_) {}
    }
    ++_generation;
    _pendingOpen = null;
    unread = 0;
    items = [];
    _wasSignedIn = false;
    await _setBadge(0);
    notifyListeners();
  }

  Future<void> refresh() {
    if (!store.signedIn) return Future<void>.value();
    return _refreshTask ??= _doRefresh().whenComplete(() => _refreshTask = null);
  }

  Future<void> _doRefresh() async {
    final generation = _generation;
    final sessionToken = store.api.token;
    try {
      final r = await store.api.notifications();
      if (store.signedIn && generation == _generation && sessionToken == store.api.token) {
        items = (r['items'] as List? ?? []).whereType<Map>()
          .map((e)=>Map<String,dynamic>.from(e)).toList();
        unread = (r['unread'] as num?)?.toInt() ?? 0;
        unawaited(_setBadge(unread));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> read(int id) async {
    if (!store.signedIn || id <= 0) return;
    final match = items.where((item) => '${item['id']}' == '$id').toList();
    final wasUnread = match.isNotEmpty && match.first['read_at'] == null;
    // Optimistic update: notification disappears immediately from the unread list.
    if (wasUnread) {
      for (final item in items) {
        if ('${item['id']}' == '$id') item['read_at'] = DateTime.now().toIso8601String();
      }
      unread = unread > 0 ? unread - 1 : 0;
      unawaited(_setBadge(unread));
      notifyListeners();
    }
    try { await store.api.markNotificationRead(id); }
    catch (_) { await refresh(); return; }
    // Sync the badge even when a terminated-app tap arrives before the inbox loads.
    await refresh();
  }

  Map<String,dynamic>? find(int id) {
    for (final item in items) { if ('${item['id']}' == '$id') return item; }
    return null;
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tokenStream?.cancel();
    _foregroundStream?.cancel();
    _openedStream?.cancel();
    store.removeListener(_authChanged);
    super.dispose();
  }
}

class NotificationDetailScreen extends StatelessWidget {
  final Map<String,dynamic> item;
  const NotificationDetailScreen({super.key,required this.item});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title:const Text('Bildirim detayı')),
    body: SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(22),child:
      Container(width:double.infinity,padding:const EdgeInsets.all(23),
        decoration:BoxDecoration(color:Colors.white,border:Border.all(color:const Color(0xFFE1EAE1)),borderRadius:BorderRadius.circular(22)),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Icon(Icons.notifications_active_outlined,color:forest,size:30),
          const SizedBox(height:18),
          Text('${item['title'] ?? 'Duyuru'}',style:Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height:15),
          Text('${item['body'] ?? ''}',style:const TextStyle(fontSize:16,height:1.65)),
          const SizedBox(height:22),
          Text('${item['created_at'] ?? ''}',style:const TextStyle(color:muted,fontSize:12)),
        ])))));
}

class NotificationsScreen extends StatefulWidget {
  final AcademyNotifications notifications;
  final AcademyStore store;
  final int? openNotificationId;
  const NotificationsScreen({super.key,required this.notifications,required this.store,this.openNotificationId});
  @override State<NotificationsScreen> createState()=>_NotificationsScreenState();
}
class _NotificationsScreenState extends State<NotificationsScreen> {
  bool initialOpened=false;
  @override void initState() {
    super.initState();
    unawaited(_load());
  }
  Future<void> _load() async {
    await widget.notifications.refresh();
    if (mounted && !initialOpened && widget.openNotificationId != null) {
      initialOpened=true;
      var item=widget.notifications.find(widget.openNotificationId!);
      if(item == null) {
        try { item = await widget.store.api.notificationDetail(widget.openNotificationId!); }
        catch (_) { /* May have been deleted, revoked or outside inbox history. */ }
      }
      if (item != null && mounted) await _open(item);
    }
  }
  Future<void> _open(Map<String,dynamic> item) async {
    final id=int.tryParse('${item['id']}')??0;
    final lessonId=int.tryParse('${item['lesson_id']}')??0;
    await widget.notifications.read(id);
    if (!mounted) return;
    await Navigator.push(context,MaterialPageRoute(builder:(_) => lessonId > 0
       ? LessonScreen(store:widget.store,id:lessonId)
       : NotificationDetailScreen(item:item)));
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Bildirimler',style:TextStyle(fontWeight:FontWeight.w800))),
    body:AnimatedBuilder(animation:widget.notifications,builder:(context,_){
      final n=widget.notifications;
      if(!widget.store.signedIn)return const Center(child:Text('Bildirimleri görmek için giriş yap.'));
      // Read messages no longer appear in this inbox.
      final visible=n.items.where((item)=>item['read_at']==null).toList();
      if(visible.isEmpty)return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Icon(Icons.notifications_none_rounded,size:58,color:forest),const SizedBox(height:12),
        const Text('Okunmamış bildirimin yok'),const SizedBox(height:10),
        TextButton(onPressed:n.refresh,child:const Text('Yenile'))]));
      return RefreshIndicator(onRefresh:n.refresh,child:ListView.separated(
        padding:const EdgeInsets.all(18),itemCount:visible.length,
        separatorBuilder:(_,__)=>const SizedBox(height:9),
        itemBuilder:(context,i){
          final item=visible[i];
          final kind=item['kind']?.toString()??'';
          return Material(color:const Color(0xFFF0F7E9),borderRadius:BorderRadius.circular(18),
            child:InkWell(borderRadius:BorderRadius.circular(18),onTap:()=>_open(item),
              child:Padding(padding:const EdgeInsets.all(16),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Icon(kind=='lesson'?Icons.menu_book_rounded:kind=='resume'?Icons.play_circle_outline:Icons.notifications_outlined,color:forest),
                const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(item['title']?.toString()??'',style:const TextStyle(fontWeight:FontWeight.w900)),
                  const SizedBox(height:6),Text(item['body']?.toString()??'',style:const TextStyle(color:muted,height:1.4)),
                  const SizedBox(height:8),Text(item['created_at']?.toString()??'',style:const TextStyle(color:muted,fontSize:11)),
                ])),Container(width:8,height:8,decoration:const BoxDecoration(color:Colors.red,shape:BoxShape.circle)),
              ]))));
        }));
    }));
}
