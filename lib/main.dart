import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'api.dart';
import 'store.dart';
import 'theme.dart';
import 'components.dart';
import 'home.dart';
import 'catalog.dart';
import 'account.dart';
import 'notifications.dart';
import 'lesson.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor:Colors.transparent,statusBarIconBrightness:Brightness.dark,systemNavigationBarColor:paper,systemNavigationBarIconBrightness:Brightness.dark));
  final store=AcademyStore(AcademyApi());
  final notifications=AcademyNotifications(store);
  store.beforeSignOut=notifications.beforeLogout;
  runApp(MuratIleOgrenApp(store:store,notifications:notifications));
  store.initialize();
  notifications.initialize();
}

class MuratIleOgrenApp extends StatelessWidget {
  final AcademyStore store;
  final AcademyNotifications notifications;
  const MuratIleOgrenApp({super.key,required this.store,required this.notifications});
  @override Widget build(BuildContext context)=>MaterialApp(
    title:'Murat İle Öğren',debugShowCheckedModeBanner:false,theme:academyTheme(),
    locale:const Locale('tr','TR'),
    supportedLocales:const [Locale('tr','TR'),Locale('en','US')],
    localizationsDelegates:[
      GlobalMaterialLocalizations.delegate,GlobalWidgetsLocalizations.delegate,GlobalCupertinoLocalizations.delegate,
    ],
    builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:MediaQuery.textScalerOf(context).clamp(minScaleFactor:1,maxScaleFactor:1.3)),child:child!),
    home:BrandedSplashGate(store:store,notifications:notifications),
  );
}


class BrandedSplashGate extends StatefulWidget {
  final AcademyStore store;
  final AcademyNotifications notifications;
  const BrandedSplashGate({super.key,required this.store,required this.notifications});
  @override State<BrandedSplashGate> createState()=>_BrandedSplashGateState();
}
class _BrandedSplashGateState extends State<BrandedSplashGate> {
  bool ready=false;
  @override void initState(){super.initState();
    Future<void>.delayed(const Duration(milliseconds:1800),(){if(mounted)setState(()=>ready=true);});
  }
  @override Widget build(BuildContext context)=>AnimatedSwitcher(duration:const Duration(milliseconds:440),child:
    ready?AcademyShell(key:const ValueKey('academy'),store:widget.store,notifications:widget.notifications):
    const _BrandSplashScreen(key:ValueKey('splash')));
}

/// Responsive splash with the ORIGINAL MG logo and the full academy name.
/// Background icons are intentionally small, monochrome and faint.
class _BrandSplashScreen extends StatelessWidget {
  const _BrandSplashScreen({super.key});
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:Colors.white,
    body:LayoutBuilder(builder:(context,c){
      final w=c.maxWidth,h=c.maxHeight;
      const icons=<IconData>[
        Icons.grid_on_outlined,Icons.description_outlined,Icons.computer_outlined,
        Icons.table_chart_outlined,Icons.keyboard_outlined,Icons.slideshow_outlined,
        Icons.school_outlined,Icons.mouse_outlined,Icons.folder_outlined,
        Icons.functions_outlined,Icons.laptop_mac_outlined,Icons.bar_chart_outlined,
        Icons.ondemand_video_outlined,Icons.menu_book_outlined,Icons.devices_outlined,
      ];
      const coords=<Offset>[
        Offset(.08,.08),Offset(.75,.10),Offset(.38,.16),Offset(.14,.26),
        Offset(.88,.28),Offset(.61,.33),Offset(.06,.46),Offset(.87,.51),
        Offset(.20,.67),Offset(.79,.72),Offset(.42,.82),Offset(.07,.91),
        Offset(.89,.90),Offset(.61,.14),Offset(.28,.40),
      ];
      return Stack(children:[
        for(var i=0;i<icons.length;i++)Positioned(left:w*coords[i].dx-20,top:h*coords[i].dy-20,
          child:Icon(icons[i],size:i.isEven?37:31,color:const Color(0xFFBFC5C1).withValues(alpha:.26))),
        Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
          Container(width:w*.53>220?220:w*.53,height:w*.53>220?220:w*.53,
            decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(44),
              boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.065),blurRadius:26,offset:const Offset(0,10))]),
            padding:const EdgeInsets.all(6),child:Image.asset('assets/logo.png',fit:BoxFit.contain)),
          const SizedBox(height:25),
          Text('Murat İle Öğren',textAlign:TextAlign.center,
            style:TextStyle(color:ink,fontSize:w>400?29:25,fontWeight:FontWeight.w900,letterSpacing:-.6)),
          const SizedBox(height:9),
          const Text('Dijital Eğitim Platformu',style:TextStyle(color:muted,fontSize:13,letterSpacing:.5)),
          const SizedBox(height:27),
          const SizedBox(width:28,height:28,child:CircularProgressIndicator(strokeWidth:2,color:forest)),
        ])),
      ]);
    }));
}

class AcademyShell extends StatefulWidget {
  final AcademyStore store;
  final AcademyNotifications notifications;
  const AcademyShell({super.key,required this.store,required this.notifications});
  @override State<AcademyShell> createState()=>_AcademyShellState();
}
class _AcademyShellState extends State<AcademyShell>{
  int index=0;
  bool _openingPush=false;

  @override void initState(){
    super.initState();
    widget.notifications.addListener(_checkPushRoute);
    widget.store.addListener(_checkPushRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPushRoute());
  }

  void _checkPushRoute(){
    if(!mounted || _openingPush || !widget.store.signedIn)return;
    // Schedule after build. FCM may arrive while splash is transitioning.
    _openingPush=true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if(!mounted){_openingPush=false;return;}
      final target=widget.notifications.takePendingOpen();
      if(target==null){_openingPush=false;return;}
      final id=(target['notification_id'] as int?)??0;
      final lessonId=(target['lesson_id'] as int?)??0;
      if(id>0) await widget.notifications.read(id);
      if(!mounted || !widget.store.signedIn){_openingPush=false;return;}
      if(lessonId>0){
        await Navigator.of(context).push(MaterialPageRoute(
          builder:(_)=>LessonScreen(store:widget.store,id:lessonId)));
      }else{
        await Navigator.of(context).push(MaterialPageRoute(
          builder:(_)=>NotificationsScreen(
            store:widget.store,
            notifications:widget.notifications,
            openNotificationId:id>0?id:null,
          )));
      }
      _openingPush=false;
      _checkPushRoute();
    });
  }

  @override void dispose(){
    widget.notifications.removeListener(_checkPushRoute);
    widget.store.removeListener(_checkPushRoute);
    super.dispose();
  }

  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.store,builder:(context,_){
    final store=widget.store;
    // Recreate widget instances on session changes while preserving State by key.
    // Reusing the exact same widget instances makes IndexedStack skip updates.
    final screens=<Widget>[
      HomeScreen(key:const ValueKey('tab-home'),store:store),
      CatalogScreen(key:const ValueKey('tab-catalog'),store:store),
      _LearningLanding(key:const ValueKey('tab-learning'),store:store),
      ProfileScreen(key:const ValueKey('tab-profile'),store:store),
    ];
    return Scaffold(
      appBar:index==0||index==3?AppBar(title:const LogoWordmark(small:true),actions:[
        if(index==0)IconButton(tooltip:'Ara',onPressed:()=>setState(()=>index=1),icon:const Icon(Icons.search_rounded)),
        if(store.signedIn)AnimatedBuilder(animation:widget.notifications,builder:(ctx,_)=>IconButton(
          tooltip:'Bildirimler',
          onPressed:()=>Navigator.push(ctx,MaterialPageRoute(builder:(_)=>NotificationsScreen(store:store,notifications:widget.notifications))),
          icon:Badge(isLabelVisible:widget.notifications.unread>0,
            label:Text(widget.notifications.unread>99?'99+':'${widget.notifications.unread}'),
            backgroundColor:Colors.red,child:const Icon(Icons.notifications_none_rounded)))),
        if(index==0)IconButton(tooltip:'Profil',onPressed:()=>setState(()=>index=3),icon:const Icon(Icons.account_circle_outlined)),
        const SizedBox(width:8),
      ]):null,
      body:store.busy && store.categories.isEmpty
          ?const Center(child:Column(mainAxisSize:MainAxisSize.min,children:[CircularProgressIndicator(color:forest),SizedBox(height:17),Text('Eğitimler hazırlanıyor...',style:TextStyle(color:muted))]))
          :store.error!=null && store.categories.isEmpty
              ?StateMessage(store.error!,retry:store.reload,icon:Icons.cloud_off_outlined)
              :IndexedStack(index:index,children:screens),
      bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),
        height:73,backgroundColor:Colors.white,indicatorColor:lime.withValues(alpha:.32),
        labelTextStyle:WidgetStateProperty.resolveWith((states)=>TextStyle(fontSize:11,fontWeight:states.contains(WidgetState.selected)?FontWeight.w800:FontWeight.w600,color:states.contains(WidgetState.selected)?forest:muted)),
        destinations:const [
          NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded),label:'Keşfet'),
          NavigationDestination(icon:Icon(Icons.grid_view_outlined),selectedIcon:Icon(Icons.grid_view_rounded),label:'Eğitimler'),
          NavigationDestination(icon:Icon(Icons.play_circle_outline),selectedIcon:Icon(Icons.play_circle_fill_rounded),label:'Derslerim'),
          NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person_rounded),label:'Profil'),
        ]),
    );
  });
}
class _LearningLanding extends StatelessWidget{
  final AcademyStore store;const _LearningLanding({super.key,required this.store});
  @override Widget build(BuildContext context){if(!store.signedIn)return Center(child:Padding(padding:const EdgeInsets.all(27),child:Column(mainAxisSize:MainAxisSize.min,children:[
    const Icon(Icons.auto_stories_outlined,color:forest,size:55),const SizedBox(height:17),Text('Derslerin seni bekliyor.',style:Theme.of(context).textTheme.headlineMedium),
    const SizedBox(height:12),const Text('İlerlemeni görmek ve kaldığın yerden devam etmek için giriş yap.',textAlign:TextAlign.center,style:TextStyle(color:muted)),
    const SizedBox(height:24),FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LoginScreen(store:store))),child:const Text('Giriş yap'))
  ])));
    return _LearningLoaded(store:store);
  }
}
class _LearningLoaded extends StatelessWidget{
  final AcademyStore store; const _LearningLoaded({required this.store});
  @override Widget build(BuildContext context){
    // MyLearningScreen owns its own async refresh / progress query.
    return MyLearningScreen(store:store);
  }
}
