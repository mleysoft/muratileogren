import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'in_app_browser.dart';
import 'api.dart';
import 'components.dart';
import 'store.dart';
import 'theme.dart';
import 'account.dart';

class LessonScreen extends StatefulWidget {
  final AcademyStore store;final int id;
  const LessonScreen({super.key,required this.store,required this.id});
  @override State<LessonScreen> createState()=>_LessonScreenState();
}
class _LessonScreenState extends State<LessonScreen>{
  late Future<Map<String,dynamic>> future;
  @override void initState(){super.initState();future=widget.store.api.lesson(widget.id);}
  void refresh()=>setState(()=>future=widget.store.api.lesson(widget.id));
  Future<void> download(Map<String,dynamic> l)async {
    try{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Dosya hazırlanıyor...')));
      final data=await widget.store.api.download(widget.id);
      final dir=await getTemporaryDirectory();
      final raw=str(l['attachment_name'],'ders-dosyasi.xlsx');
      final safe=raw.replaceAll(RegExp(r'[^a-zA-Z0-9ÇĞİÖŞÜçğıöşü ._\-]'),'_');
      final f=File('${dir.path}/$safe');await f.writeAsBytes(data,flush:true);
      await SharePlus.instance.share(ShareParams(files:[XFile(f.path)],text:'Murat İle Öğren ders uygulama dosyası'));
    }catch(e){if(mounted)showFailure(context,e);}
  }
  Future<void> rate(Map<String,dynamic> l)async{
    if(!widget.store.signedIn){await Navigator.push(context,MaterialPageRoute(builder:(_)=>LoginScreen(store:widget.store)));if(!mounted)return;
      if(widget.store.signedIn){refresh();try{l=Map<String,dynamic>.from((await widget.store.api.lesson(widget.id))['lesson']);}catch(_){}}
    }
    if(l['can_watch']!=true){showFailure(context,const ApiError('Bu ders için aktif abonelik gerekiyor.'));return;}
    final current=asInt(l['my_rating']);
    final stars=await showModalBottomSheet<int>(context:context,showDragHandle:true,isScrollControlled:true,builder:(ctx)=>_RatingPicker(current:current));
    if(stars==null)return;
    try{await widget.store.api.rate(widget.id,stars);if(mounted){refresh();ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Değerlendirmen kaydedildi.')));}}
    catch(e){if(mounted)showFailure(context,e);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Ders izleme',style:TextStyle(fontWeight:FontWeight.w900))),
    body:FutureBuilder<Map<String,dynamic>>(future:future,builder:(ctx,s){
      if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return StateMessage(s.error.toString(),retry:refresh);
      final l=Map<String,dynamic>.from(s.data!['lesson']);
      final cat=s.data!['category'] is Map ? Map<String,dynamic>.from(s.data!['category']) : <String,dynamic>{};
      return ListView(padding:const EdgeInsets.only(bottom:45),children:[
        Container(margin:const EdgeInsets.fromLTRB(18,5,18,3),padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(23),border:Border.all(color:soft)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Eyebrow(str(cat['title'],'Dijital eğitim')),const SizedBox(height:11),
          Text(str(l['title']),style:Theme.of(context).textTheme.headlineLarge),const SizedBox(height:14),
          Wrap(spacing:10,runSpacing:10,crossAxisAlignment:WrapCrossAlignment.center,children:[
            SoftBadge(durationText(l['duration_sec'])),
            RatingRow(rating:l['rating'],count:l['rating_count']),
            if(l['completed']==true)const SoftBadge('✓ Tamamlandı'),
            if(l['is_free']==true)const SoftBadge('Ücretsiz'),
          ]),
        ])),
        const SizedBox(height:18),
        if(l['can_watch']==true && l['has_video']==true)
           (l['video_type']=='file'
             ? LessonVideo(store:widget.store,lessonId:widget.id,initialPosition:asInt(l['position_sec']),onComplete:(){if(mounted){refresh();widget.store.reload();}})
             : Container(padding:const EdgeInsets.all(24),child:FilledButton.icon(onPressed:()async{
                 final u=Uri.tryParse(str(l['external_url']));
                 if(u!=null && u.scheme=='https' && context.mounted){await Navigator.push(context,MaterialPageRoute(builder:(_)=>InAppBrowser(title:'Ders videosu',path:u.toString())));}
               },icon:const Icon(Icons.open_in_new),label:const Text('Videoyu aç'))))
        else Container(height:205,margin:const EdgeInsets.symmetric(horizontal:20),decoration:BoxDecoration(color:ink,borderRadius:BorderRadius.circular(22)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
          Icon(l['can_watch']==true?Icons.movie_filter_outlined:Icons.lock_outline,size:42,color:lime),const SizedBox(height:13),
          Text(l['can_watch']==true?'Video yakında eklenecek':'Dersi izlemek için giriş yap veya üyeliğini etkinleştir.',textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,fontSize:13)),
          if(!widget.store.signedIn)...[const SizedBox(height:10),TextButton(onPressed:()async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>LoginScreen(store:widget.store)));if(mounted)refresh();},child:const Text('Giriş yap',style:TextStyle(color:lime)))],
        ])),
        const SizedBox(height:20),Container(margin:const EdgeInsets.symmetric(horizontal:18),padding:const EdgeInsets.all(19),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:soft),borderRadius:BorderRadius.circular(23)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Eyebrow('Ders hakkında'),const SizedBox(height:8),
          Text(str(l['summary']),style:const TextStyle(fontSize:14,height:1.6,color:ink)),
          if(str(l['content']).isNotEmpty)...[const SizedBox(height:14),Text(str(l['content']).replaceAll('**','').replaceAll('`',''),style:const TextStyle(fontSize:13,height:1.8,color:ink))],
          const SizedBox(height:24),
          if(l['has_attachment']==true && l['can_watch']==true)...[
            Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:soft)),child:Row(children:[
              const Icon(Icons.file_download_outlined,color:forest,size:30),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                const Text('Uygulama dosyası',style:TextStyle(fontWeight:FontWeight.w800)),Text(str(l['attachment_name'],'Ders dosyasını indir'),style:const TextStyle(color:muted,fontSize:12))])),
              IconButton(onPressed:()=>download(l),icon:const Icon(Icons.download_rounded,color:forest))
            ])),const SizedBox(height:19),
          ],
          OutlinedButton.icon(onPressed:()=>rate(l),icon:const Icon(Icons.star_border),label:Text(asInt(l['my_rating'])>0?'Puanını güncelle':'Bu dersi değerlendir')),
          const SizedBox(height:13),if(asInt(l['views'])>0)Text('${trCount(l['views'])} görüntüleme • ${trCount(l['watches'])} video izleyen',style:const TextStyle(color:muted,fontSize:11)),
        ]))
      ]);
    }));
}

class _RatingPicker extends StatefulWidget {
  final int current;const _RatingPicker({required this.current});
  @override State<_RatingPicker> createState()=>_RatingPickerState();
}
class _RatingPickerState extends State<_RatingPicker>{
  late int selected;
  @override void initState(){super.initState();selected=widget.current>0?widget.current:5;}
  @override Widget build(BuildContext context)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(24,12,24,26),child:Column(mainAxisSize:MainAxisSize.min,children:[
    Text('Dersi nasıl buldun?',style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:14),
    Row(mainAxisAlignment:MainAxisAlignment.center,children:List.generate(5,(i)=>IconButton(onPressed:()=>setState(()=>selected=i+1),icon:Icon(i<selected?Icons.star_rounded:Icons.star_outline_rounded,size:38,color:const Color(0xFFE6A32E))))),
    const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(context,selected),child:const Text('Puanı kaydet')))
  ])));
}

class LessonVideo extends StatefulWidget {
  final AcademyStore store;final int lessonId,initialPosition;final VoidCallback onComplete;
  const LessonVideo({super.key,required this.store,required this.lessonId,required this.initialPosition,required this.onComplete});
  @override State<LessonVideo> createState()=>_LessonVideoState();
}
class _LessonVideoState extends State<LessonVideo> with WidgetsBindingObserver {
  VideoPlayerController? controller;Timer? tick;String? error;bool ready=false;
  int lastSent=0;bool completedSignal=false;
  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);load();}
  Future<void> load()async{
    final c=VideoPlayerController.networkUrl(widget.store.api.videoUri(widget.lessonId),httpHeaders:widget.store.api.authHeaders);
    controller=c;
    try{
      await c.initialize();if(!mounted)return;
      if(widget.initialPosition>0&&widget.initialPosition<c.value.duration.inSeconds)await c.seekTo(Duration(seconds:widget.initialPosition));
      c.addListener(onPosition);
      setState(()=>ready=true);
      tick=Timer.periodic(const Duration(seconds:10),(_){save();});
      await c.play();
    }catch(e){if(mounted)setState(()=>error='Video açılamadı. Sunucunun özel video depolama alanını kontrol et.');}
  }
  void onPosition(){final c=controller;if(c==null || !mounted)return;
    if(c.value.isCompleted && !completedSignal){completedSignal=true;save(force:true);widget.onComplete();}
    else if(ready && c.value.duration.inSeconds>0 && c.value.position.inSeconds >= c.value.duration.inSeconds*.9 && !completedSignal){
      completedSignal=true;save(force:true);widget.onComplete();
    }
    setState((){});
  }
  Future<void> save({bool force=false})async{
    final c=controller;if(c==null||!ready||!widget.store.signedIn)return;
    final pos=c.value.position.inSeconds;
    if(!force && (pos-lastSent).abs()<5)return;
    lastSent=pos;
    try{await widget.store.api.updateProgress(widget.lessonId,pos,c.value.duration.inSeconds);}catch(_){} // don't interrupt playback
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state!=AppLifecycleState.resumed){controller?.pause();save(force:true);}}
  @override void dispose(){WidgetsBinding.instance.removeObserver(this);tick?.cancel();save(force:true);controller?.removeListener(onPosition);controller?.dispose();super.dispose();}
  String timestamp(Duration d){final s=d.inSeconds;return '${s~/60}:${(s%60).toString().padLeft(2,'0')}';}
  Future<void> fullscreen()async{
    final c=controller;if(c==null)return;
    await Navigator.push(context,MaterialPageRoute(builder:(_)=>_FullscreenVideo(controller:c)));
  }
  @override Widget build(BuildContext context){
    if(error!=null)return Container(height:210,margin:const EdgeInsets.symmetric(horizontal:20),padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:ink,borderRadius:BorderRadius.circular(20)),child:StateMessage(error!,icon:Icons.error_outline));
    if(!ready||controller==null)return Container(height:205,margin:const EdgeInsets.symmetric(horizontal:20),decoration:BoxDecoration(color:ink,borderRadius:BorderRadius.circular(21)),child:const Center(child:CircularProgressIndicator(color:lime)));
    final c=controller!;
    return Container(margin:const EdgeInsets.symmetric(horizontal:16),decoration:BoxDecoration(color:ink,borderRadius:BorderRadius.circular(21)),clipBehavior:Clip.antiAlias,child:Column(children:[
      AspectRatio(aspectRatio:c.value.aspectRatio>0?c.value.aspectRatio:16/9,child:GestureDetector(onTap:()=>setState(()=>c.value.isPlaying?c.pause():c.play()),child:Stack(alignment:Alignment.center,children:[
        VideoPlayer(c),if(!c.value.isPlaying)Container(decoration:BoxDecoration(shape:BoxShape.circle,color:Colors.black.withValues(alpha:.5)),child:const Padding(padding:EdgeInsets.all(14),child:Icon(Icons.play_arrow,color:Colors.white,size:34)))
      ]))),
      Padding(padding:const EdgeInsets.fromLTRB(13,4,9,10),child:Column(children:[
        VideoProgressIndicator(c,allowScrubbing:true,padding:const EdgeInsets.symmetric(vertical:8),colors:VideoProgressColors(playedColor:lime,bufferedColor:Colors.white24,backgroundColor:Colors.white10)),
        Row(children:[IconButton(icon:Icon(c.value.isPlaying?Icons.pause_rounded:Icons.play_arrow_rounded,color:Colors.white),onPressed:()=>setState(()=>c.value.isPlaying?c.pause():c.play())),
          Text('${timestamp(c.value.position)} / ${timestamp(c.value.duration)}',style:const TextStyle(fontSize:11,color:Colors.white70)),
          const Spacer(),IconButton(onPressed:fullscreen,icon:const Icon(Icons.fullscreen_rounded,color:Colors.white))])
      ]))
    ]));
  }
}
class _FullscreenVideo extends StatefulWidget{
  final VideoPlayerController controller;const _FullscreenVideo({required this.controller});
  @override State<_FullscreenVideo> createState()=>_FullscreenVideoState();
}
class _FullscreenVideoState extends State<_FullscreenVideo>{
  @override void initState(){super.initState();SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft,DeviceOrientation.landscapeRight]);SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);widget.controller.addListener(update);}
  void update(){if(mounted)setState((){});}
  @override void dispose(){widget.controller.removeListener(update);SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:Colors.black,body:SafeArea(child:Stack(children:[
    Center(child:AspectRatio(aspectRatio:widget.controller.value.aspectRatio,child:VideoPlayer(widget.controller))),
    Positioned(top:4,left:6,child:IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close,color:Colors.white))),
    Positioned(bottom:5,left:15,right:15,child:VideoProgressIndicator(widget.controller,allowScrubbing:true,colors:VideoProgressColors(playedColor:lime)))
  ])));
}
