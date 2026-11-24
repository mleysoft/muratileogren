import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'config.dart';
import 'theme.dart';

bool isApprovedHost(String host,String primary){
  if(host==primary)return true;
  const allowed=['youtube.com','youtu.be','youtube-nocookie.com','vimeo.com','player.vimeo.com'];
  return allowed.any((domain)=>host==domain || host.endsWith('.$domain'));
}

/// Browse only the academy's HTTPS host inside the Flutter application.
class InAppBrowser extends StatefulWidget {
  final String title;
  final String path;
  const InAppBrowser({super.key,required this.title,required this.path});
  @override State<InAppBrowser> createState()=>_InAppBrowserState();
}
class _InAppBrowserState extends State<InAppBrowser> {
  late final WebViewController controller;
  int loading=0;
  String? error;
  @override void initState() {
    super.initState();
    final base=Uri.parse(AppConfig.site);
    final path=widget.path.startsWith('/')?widget.path:'/${widget.path}';
    final target=widget.path.startsWith('https://')?Uri.parse(widget.path):Uri.parse('${AppConfig.site}$path');
    controller=WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF7F9F5))
      ..setNavigationDelegate(NavigationDelegate(
        onProgress:(value){if(mounted)setState(()=>loading=value);},
        onPageStarted:(_){if(mounted)setState(()=>error=null);},
        onWebResourceError:(err){if(err.isForMainFrame==true && mounted)setState(()=>error='Sayfa yüklenemedi. Bağlantını kontrol et.');},
        onNavigationRequest:(nav){
          final u=Uri.tryParse(nav.url);
          if(u==null || u.scheme!='https' || !isApprovedHost(u.host,base.host))return NavigationDecision.prevent;
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(target);
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800)),actions:[IconButton(tooltip:'Yenile',onPressed:()=>controller.reload(),icon:const Icon(Icons.refresh_rounded))]),
    body:Stack(children:[
      if(error==null)WebViewWidget(controller:controller)
      else Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Icon(Icons.wifi_off_rounded,color:forest,size:42),const SizedBox(height:14),Text(error!,textAlign:TextAlign.center),const SizedBox(height:14),
        FilledButton(onPressed:()=>controller.reload(),child:const Text('Yeniden dene'))]))),
      if(loading<100 && error==null)Positioned(top:0,left:0,right:0,child:LinearProgressIndicator(value:loading/100,minHeight:3,color:forest,backgroundColor:Colors.transparent)),
    ]),
  );
}

class LegalDocumentsScreen extends StatefulWidget {
  const LegalDocumentsScreen({super.key});
  @override State<LegalDocumentsScreen> createState()=>_LegalDocumentsState();
}
class _LegalDocumentsState extends State<LegalDocumentsScreen> {
  int current=0;
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Gizlilik ve üyelik koşulları')),
    body:Column(children:[Padding(padding:const EdgeInsets.fromLTRB(15,8,15,10),child:Row(children:[
      for(final pair in [(0,'Gizlilik politikası'),(1,'Üyelik koşulları')])Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:4),child:ChoiceChip(
        label:Text(pair.$2,style:const TextStyle(fontSize:12)),selected:current==pair.$1,
        onSelected:(_)=>setState(()=>current=pair.$1))))
    ])),Expanded(child:InAppBrowserBody(key:ValueKey(current),path:current==0?'/gizlilik-politikasi':'/uyelik-kosullari'))]));
}
class InAppBrowserBody extends StatefulWidget {
  final String path;
  const InAppBrowserBody({super.key,required this.path});
  @override State<InAppBrowserBody> createState()=>_InAppBrowserBodyState();
}
class _InAppBrowserBodyState extends State<InAppBrowserBody> {
  late final WebViewController controller;
  bool loading=true;
  String? error;
  @override void initState(){super.initState();
    controller=WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF7F9F5))
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted:(_){if(mounted)setState((){loading=true;error=null;});},
        onPageFinished:(_){if(mounted)setState(()=>loading=false);},
        onWebResourceError:(e){if(e.isForMainFrame==true && mounted)setState((){loading=false;error='Sayfa açılamadı.';});},
        onNavigationRequest:(nav){final uri=Uri.tryParse(nav.url);return uri!=null&&uri.scheme=='https'&&uri.host==Uri.parse(AppConfig.site).host?NavigationDecision.navigate:NavigationDecision.prevent;},
      ))..loadRequest(Uri.parse('${AppConfig.site}${widget.path}'));
  }
  @override Widget build(BuildContext context)=>Stack(children:[WebViewWidget(controller:controller),if(loading)const Center(child:CircularProgressIndicator()),
    if(error!=null)Center(child:FilledButton.icon(onPressed:()=>controller.reload(),icon:const Icon(Icons.refresh),label:const Text('Tekrar yükle')))]);
}
