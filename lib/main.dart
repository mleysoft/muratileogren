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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor:Colors.transparent,statusBarIconBrightness:Brightness.dark,systemNavigationBarColor:paper,systemNavigationBarIconBrightness:Brightness.dark));
  final store=AcademyStore(AcademyApi());
  runApp(MuratIleOgrenApp(store:store));
  store.initialize();
}

class MuratIleOgrenApp extends StatelessWidget {
  final AcademyStore store;
  const MuratIleOgrenApp({super.key,required this.store});
  @override Widget build(BuildContext context)=>MaterialApp(
    title:'MG İle Öğren',debugShowCheckedModeBanner:false,theme:academyTheme(),
    locale:const Locale('tr','TR'),
    supportedLocales:const [Locale('tr','TR'),Locale('en','US')],
    localizationsDelegates:[
      GlobalMaterialLocalizations.delegate,GlobalWidgetsLocalizations.delegate,GlobalCupertinoLocalizations.delegate,
    ],
    builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:MediaQuery.textScalerOf(context).clamp(minScaleFactor:1,maxScaleFactor:1.3)),child:child!),
    home:BrandedSplashGate(store:store),
  );
}


class BrandedSplashGate extends StatefulWidget {
  final AcademyStore store;
  const BrandedSplashGate({super.key,required this.store});
  @override State<BrandedSplashGate> createState()=>_BrandedSplashGateState();
}
class _BrandedSplashGateState extends State<BrandedSplashGate> {
  bool ready=false;
  @override void initState(){super.initState();
    Future<void>.delayed(const Duration(milliseconds:1800),(){if(mounted)setState(()=>ready=true);});
  }
  @override Widget build(BuildContext context)=>AnimatedSwitcher(duration:const Duration(milliseconds:440),child:
    ready?AcademyShell(key:const ValueKey('academy'),store:widget.store):
    Scaffold(key:const ValueKey('splash'),backgroundColor:Colors.white,
      body:SizedBox.expand(child:Image.asset('assets/splash_full.png',fit:BoxFit.cover,filterQuality:FilterQuality.high))));
}

class AcademyShell extends StatefulWidget {
  final AcademyStore store;
  const AcademyShell({super.key,required this.store});
  @override State<AcademyShell> createState()=>_AcademyShellState();
}
class _AcademyShellState extends State<AcademyShell>{
  int index=0;
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
