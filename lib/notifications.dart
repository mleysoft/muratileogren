import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  // Update icon badges natively, without any third-party badge plugin.
  // iOS: immediately update the SpringBoard badge after read/logout.
  // Android: remove outstanding tray notifications when no unread items
  // remain; number/dot rendering depends on the device launcher.
  static const MethodChannel _badgeChannel = MethodChannel('muratileogren/notification_badge');
  Future<void> _setBadge(int count) async {
    try {
      await _badgeChannel.invokeMethod<void>('setBadge', <String, int>{
        'count': count.clamp(0, 999).toInt(),
      });
    } on MissingPluginException {
      // Native shell has not yet been regenerated with the channel bridge.
    } on PlatformException {
      // Permission/launcher may not support app icon badges.
    }
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

  Future<void> deleteRead(int id) async {
    if (!store.signedIn || id <= 0) return;
    final item = find(id);
    if (item == null || item['read_at'] == null) {
      throw StateError('Yalnızca okunmuş bildirimler silinebilir.');
    }
    final token = store.api.token;
    final generation = _generation;
    // Keep the row visible until the server confirms deletion.
    await store.api.deleteReadNotification(id);
    if (store.signedIn && token == store.api.token && generation == _generation) {
      items = items.where((e) => '${e['id']}' != '$id').toList();
      notifyListeners();
    }
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
  bool initialOpened = false;
  int selectedTab = 0; // 0 unread, 1 read
  int? swipedNotificationId;
  double swipeDistance = 0;
  int? deletingId;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    await widget.notifications.refresh();
    if (mounted && !initialOpened && widget.openNotificationId != null) {
      initialOpened = true;
      var item = widget.notifications.find(widget.openNotificationId!);
      if (item == null) {
        try {
          item = await widget.store.api.notificationDetail(widget.openNotificationId!);
        } catch (_) {
          // It may have been deleted or may belong to another account.
        }
      }
      if (item != null && mounted) await _open(item);
    }
  }

  Future<void> _open(Map<String,dynamic> item) async {
    final id = int.tryParse('${item['id']}') ?? 0;
    final lessonId = int.tryParse('${item['lesson_id']}') ?? 0;
    if (item['read_at'] == null) await widget.notifications.read(id);
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => lessonId > 0
      ? LessonScreen(store: widget.store, id: lessonId)
      : NotificationDetailScreen(item: item)));
  }

  Future<void> _delete(int id) async {
    if (deletingId != null) return;
    setState(() => deletingId = id);
    try {
      await widget.notifications.deleteRead(id);
      if (!mounted) return;
      setState(() {
        swipedNotificationId = null;
        swipeDistance = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bildirim silindi.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bildirim silinemedi: $e')));
    } finally {
      if (mounted) setState(() => deletingId = null);
    }
  }

  void _onSwipeUpdate(int id, DragUpdateDetails details) {
    if (deletingId != null) return;
    setState(() {
      if (swipedNotificationId != id) {
        swipedNotificationId = id;
        swipeDistance = 0;
      }
      swipeDistance = (swipeDistance + details.delta.dx).clamp(-86.0, 0.0);
    });
  }

  void _onSwipeEnd(int id) {
    setState(() {
      if (swipedNotificationId == id && swipeDistance <= -32) {
        swipeDistance = -86;
      } else {
        swipedNotificationId = null;
        swipeDistance = 0;
      }
    });
  }

  Widget _notificationCard(Map<String,dynamic> item, {required bool isRead}) {
    final id = int.tryParse('${item['id']}') ?? 0;
    final kind = item['kind']?.toString() ?? '';
    final slide = isRead && swipedNotificationId == id ? swipeDistance : 0.0;
    final foreground = Material(
      color: isRead ? Colors.white : const Color(0xFFF0F7E9),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          if (slide != 0) {
            setState(() { swipedNotificationId = null; swipeDistance = 0; });
            return;
          }
          await _open(item);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(kind == 'lesson' ? Icons.menu_book_rounded
              : kind == 'resume' ? Icons.play_circle_outline
              : Icons.notifications_outlined, color: forest),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(item['body']?.toString() ?? '', style: const TextStyle(color: muted, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(item['created_at']?.toString() ?? '', style: const TextStyle(color: muted, fontSize: 11)),
            ])),
            if (!isRead) Container(width: 8,height: 8,decoration: const BoxDecoration(color: Colors.red,shape: BoxShape.circle)),
          ]),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAE2)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(children: [
        if (isRead)
          Positioned.fill(child: Align(alignment: Alignment.centerRight, child: SizedBox(
            width: 86, child: Material(color: const Color(0xFFCF3343), child: InkWell(
              onTap: deletingId == id ? null : () => _delete(id),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                deletingId == id
                    ? const SizedBox(width: 22,height: 22, child: CircularProgressIndicator(color: Colors.white,strokeWidth: 2))
                    : const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
                const SizedBox(height: 3),
                const Text('Sil',style: TextStyle(color: Colors.white,fontSize: 12,fontWeight: FontWeight.bold)),
              ]),
            )),
          ))),
        GestureDetector(
          onHorizontalDragUpdate: isRead ? (d) => _onSwipeUpdate(id, d) : null,
          onHorizontalDragEnd: isRead ? (_) => _onSwipeEnd(id) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(slide, 0, 0),
            child: foreground,
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bildirimler', style: TextStyle(fontWeight: FontWeight.w800))),
    body: AnimatedBuilder(animation: widget.notifications, builder: (context, _) {
      final n = widget.notifications;
      if (!widget.store.signedIn) return const Center(child: Text('Bildirimleri görmek için giriş yap.'));
      final unreadItems = n.items.where((i) => i['read_at'] == null).toList();
      final readItems = n.items.where((i) => i['read_at'] != null).toList();
      final visible = selectedTab == 0 ? unreadItems : readItems;
      return Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 15, 16, 8), child: Row(children: [
          _tabButton('Okunmamış', unreadItems.length, 0),
          const SizedBox(width: 9),
          _tabButton('Okunmuş', readItems.length, 1),
        ])),
        Expanded(child: RefreshIndicator(
          onRefresh: n.refresh,
          child: visible.isEmpty
            ? ListView(children: [SizedBox(
              height: MediaQuery.sizeOf(context).height * .55,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.notifications_none_rounded, size: 54, color: forest),
                const SizedBox(height: 12),
                Text(selectedTab == 0 ? 'Okunmamış bildirimin yok' : 'Okunmuş bildirimin yok'),
                const SizedBox(height: 8),
                Text(selectedTab == 0 ? 'Okuduğun bildirimler Okunmuş sekmesinde saklanır.'
                  : 'Okunan duyuru ve ders bildirimlerini burada görebilirsin.',
                  style: const TextStyle(color: muted,fontSize: 12),textAlign: TextAlign.center),
              ]),
            )])
            : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _notificationCard(visible[i], isRead: selectedTab == 1),
            ),
        )),
      ]);
    }),
  );

  Widget _tabButton(String label, int count, int index) {
    final active = selectedTab == index;
    return Expanded(child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() {
        selectedTab = index;
        swipedNotificationId = null;
        swipeDistance = 0;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? forest : Colors.white,
          border: Border.all(color: active ? forest : const Color(0xFFE2EAE2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(child: Text(label,overflow: TextOverflow.ellipsis,style: TextStyle(color: active ? Colors.white : forest,fontWeight: FontWeight.w700,fontSize: 13))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7,vertical: 2),
            decoration: BoxDecoration(
              color: active ? Colors.white.withValues(alpha: .18) : const Color(0xFFF0F7E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',style: TextStyle(fontSize: 12,color: active ? Colors.white : forest,fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    ));
  }
}
