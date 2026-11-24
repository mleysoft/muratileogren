from pathlib import Path
p=Path('/mnt/data/video_fix_work/lib/lesson.dart')
s=p.read_text()
s=s.replace('  @override void initState(){super.initState();future=widget.store.api.lesson(widget.id);}\n  void refresh()=>setState(()=>future=widget.store.api.lesson(widget.id));', '''  int? _nextLessonId;
  String? _nextLessonTitle;
  @override void initState(){super.initState();future=_loadLesson();}
  Future<Map<String,dynamic>> _loadLesson() async {
    final data=await widget.store.api.lesson(widget.id);
    // Load the next lesson without rebuilding/restarting the active player.
    unawaited(_loadNextLesson(data));
    return data;
  }
  Future<void> _loadNextLesson(Map<String,dynamic> detail) async {
    try {
      final cat=detail['category'];
      if(cat is! Map) return;
      final id=asInt(cat['id']);
      if(id<=0)return;
      final response=await widget.store.api.category(id);
      final raw=response['lessons'];
      if(raw is! List)return;
      final lessons=raw.whereType<Map>().map((item)=>Map<String,dynamic>.from(item)).toList();
      final index=lessons.indexWhere((item)=>asInt(item['id'])==widget.id);
      if(index<0 || index+1>=lessons.length)return;
      final next=lessons[index+1];
      if(mounted)setState((){
        _nextLessonId=asInt(next['id']);
        _nextLessonTitle=str(next['title']);
      });
    }catch(_){/* The current lesson must work even if next-lesson lookup fails. */}
  }
  void refresh()=>setState(()=>future=_loadLesson());
  void _openNextLesson() {
    final next=_nextLessonId;
    if(next==null || next<=0 || !mounted)return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder:(_)=>LessonScreen(store:widget.store,id:next)));
  }''')
s=s.replace("? LessonVideo(store:widget.store,lessonId:widget.id,initialPosition:asInt(l['position_sec']),onComplete:(){if(mounted){refresh();widget.store.reload();}})","? LessonVideo(key:ValueKey(widget.id),store:widget.store,lessonId:widget.id,initialPosition:asInt(l['position_sec']),nextLessonId:_nextLessonId,nextLessonTitle:_nextLessonTitle,onNext:_openNextLesson)")
start=s.index('class LessonVideo extends StatefulWidget {')
end=s.index('/// The same complete controls',start)
s=s[:start]+'''class LessonVideo extends StatefulWidget {
  final AcademyStore store;
  final int lessonId, initialPosition;
  final int? nextLessonId;
  final String? nextLessonTitle;
  final VoidCallback onNext;
  const LessonVideo({super.key,required this.store,required this.lessonId,
    required this.initialPosition,required this.nextLessonId,
    required this.nextLessonTitle,required this.onNext});
  @override State<LessonVideo> createState()=>_LessonVideoState();
}

class _LessonVideoState extends State<LessonVideo> with WidgetsBindingObserver {
  VideoPlayerController? controller;
  Timer? tick;
  Timer? countdownTimer;
  final ValueNotifier<int?> countdown=ValueNotifier<int?>(null);
  final ValueNotifier<bool> completed=ValueNotifier<bool>(false);
  String? error;
  bool ready=false;
  bool _finishedOnce=false;
  bool _navigating=false;
  bool _fullscreenOpen=false;
  int lastSent=0;

  @override void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
  }
  @override void didUpdateWidget(covariant LessonVideo oldWidget){
    super.didUpdateWidget(oldWidget);
    if(widget.nextLessonId!=oldWidget.nextLessonId && _finishedOnce){
      _beginCountdown();
    }
  }
  Future<void> load() async {
    final c=VideoPlayerController.networkUrl(
      widget.store.api.videoUri(widget.lessonId),
      httpHeaders:widget.store.api.authHeaders,
    );
    controller=c;
    try{
      await c.initialize();
      if(!mounted || controller!=c){await c.dispose();return;}
      if(widget.initialPosition>0 && widget.initialPosition<c.value.duration.inSeconds-1){
        await c.seekTo(Duration(seconds:widget.initialPosition));
      }
      c.addListener(onPosition);
      setState(()=>ready=true);
      tick=Timer.periodic(const Duration(seconds:10),(_)=>save());
      await c.play();
    }catch(_){
      if(mounted)setState(()=>error='Video açılamadı. Bağlantıyı kontrol et.');
    }
  }
  void onPosition(){
    final c=controller;
    if(c==null || !mounted || !c.value.isInitialized || _finishedOnce)return;
    // Do not complete at 90%: that previously caused a reload loop.
    if(c.value.isCompleted){
      _finishedOnce=true;
      completed.value=true;
      unawaited(save(force:true));
      // No parent refresh: keep this player mounted until user chooses next.
      _beginCountdown();
    }
  }
  void _beginCountdown(){
    if(!_finishedOnce || widget.nextLessonId==null || _navigating || countdownTimer!=null)return;
    countdown.value=8;
    countdownTimer=Timer.periodic(const Duration(seconds:1),(timer){
      if(!mounted || _navigating){timer.cancel();return;}
      final left=countdown.value;
      if(left==null){timer.cancel();return;}
      if(left<=1){timer.cancel();countdownTimer=null;countdown.value=0;_goNext();}
      else countdown.value=left-1;
    });
  }
  void _cancelCountdown(){countdownTimer?.cancel();countdownTimer=null;countdown.value=null;}
  void _goNext(){
    if(_navigating || widget.nextLessonId==null)return;
    _navigating=true;
    _cancelCountdown();
    // Close landscape route before replacing the lesson route.
    if(_fullscreenOpen){
      Navigator.of(context).pop();
      Future.delayed(const Duration(milliseconds:250),(){
        if(mounted)widget.onNext();
      });
    }else{widget.onNext();}
  }
  Future<void> _replay() async {
    _cancelCountdown();
    _finishedOnce=false;
    completed.value=false;
    final c=controller;
    if(c==null)return;
    await c.seekTo(Duration.zero);
    await c.play();
  }
  Future<void> save({bool force=false})async{
    final c=controller;
    if(c==null || !ready || !widget.store.signedIn || !c.value.isInitialized)return;
    final pos=c.value.position.inSeconds;
    if(!force && (pos-lastSent).abs()<5)return;
    lastSent=pos;
    try{await widget.store.api.updateProgress(widget.lessonId,pos,c.value.duration.inSeconds);}catch(_){ }
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state){
    if(state!=AppLifecycleState.resumed){
      controller?.pause();
      unawaited(save(force:true));
      countdownTimer?.cancel();countdownTimer=null;
    }else if(_finishedOnce && countdown.value!=null && countdown.value!>0){
      _beginCountdown();
    }
  }
  @override void dispose(){
    WidgetsBinding.instance.removeObserver(this);
    tick?.cancel();
    countdownTimer?.cancel();
    unawaited(save(force:true));
    controller?.removeListener(onPosition);
    controller?.dispose();
    countdown.dispose();
    completed.dispose();
    super.dispose();
  }
  Future<void> fullscreen() async {
    final c=controller;
    if(c==null)return;
    _fullscreenOpen=true;
    await Navigator.of(context).push(MaterialPageRoute(builder:(_)=>_FullscreenVideo(
      controller:c,completed:completed,countdown:countdown,
      nextLessonTitle:widget.nextLessonTitle,onNext:_goNext,onReplay:_replay)));
    _fullscreenOpen=false;
    if(mounted)setState((){});
  }
  @override Widget build(BuildContext context){
    if(error!=null)return Padding(padding:const EdgeInsets.all(20),child:
      StateMessage(error!,retry:(){setState((){error=null;ready=false;});
        controller?.removeListener(onPosition);controller?.dispose();load();}));
    if(!ready || controller==null)return Container(height:210,
      margin:const EdgeInsets.symmetric(horizontal:16),
      decoration:BoxDecoration(color:ink,borderRadius:BorderRadius.circular(18)),
      child:const Center(child:CircularProgressIndicator(color:lime)));
    return Padding(padding:const EdgeInsets.symmetric(horizontal:16),
      child:ClipRRect(borderRadius:BorderRadius.circular(17),child:
        _PlayerSurface(controller:controller!,fullscreen:false,onFullscreen:fullscreen,
          completed:completed,countdown:countdown,nextLessonTitle:widget.nextLessonTitle,
          onNext:_goNext,onReplay:_replay)));
  }
}

''' + s[end:]
s=s.replace('  final VoidCallback? onFullscreen;\n  const _PlayerSurface({required this.controller,required this.fullscreen,this.onFullscreen});', '''  final VoidCallback? onFullscreen;
  final ValueNotifier<bool> completed;
  final ValueNotifier<int?> countdown;
  final String? nextLessonTitle;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  const _PlayerSurface({required this.controller,required this.fullscreen,
    required this.completed,required this.countdown,required this.onNext,
    required this.onReplay,this.nextLessonTitle,this.onFullscreen});''')
s=s.replace('  @override void initState(){super.initState();widget.controller.addListener(_updated);}', '''  @override void initState(){
    super.initState();
    widget.controller.addListener(_updated);
    _scheduleHide(); // Hide initial controls after 3 seconds of playback.
  }
  void _scheduleHide(){
    _hide?.cancel();
    _hide=Timer(const Duration(seconds:3),(){
      if(mounted && widget.controller.value.isPlaying && !widget.completed.value){
        setState(()=>showing=false);
      }
    });
  }''')
s=s.replace('    _hide=Timer(const Duration(seconds:4),(){if(mounted&&widget.controller.value.isPlaying)setState(()=>showing=false);});','    _scheduleHide();')
s=s.replace('          if(v.isBuffering)const Center(child:CircularProgressIndicator(color:lime)),', '''          if(v.isBuffering && !v.isCompleted)const Center(child:CircularProgressIndicator(color:lime)),
          ValueListenableBuilder<bool>(valueListenable:widget.completed,builder:(context,isDone,_) {
            if(!isDone)return const SizedBox.shrink();
            return Positioned.fill(child:ColoredBox(color:Colors.black.withValues(alpha:.82),
              child:Center(child:Padding(padding:const EdgeInsets.all(16),child:Column(
                mainAxisSize:MainAxisSize.min,children:[
                  const Icon(Icons.check_circle_rounded,color:lime,size:36),
                  const SizedBox(height:9),
                  const Text('Ders tamamlandı',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:17)),
                  if(widget.nextLessonTitle!=null)...[
                    const SizedBox(height:7),
                    Text(widget.nextLessonTitle!,maxLines:2,textAlign:TextAlign.center,
                      overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white70,fontSize:12)),
                    const SizedBox(height:8),
                    ValueListenableBuilder<int?>(valueListenable:widget.countdown,
                      builder:(_,left,__)=>Text(left==null?'Sonraki ders hazırlanıyor...':
                        'Sonraki derse ${left} saniye sonra geçilecek',
                        textAlign:TextAlign.center,style:const TextStyle(color:lime,fontSize:12))),
                    const SizedBox(height:9),
                    FilledButton(onPressed:widget.onNext,child:const Text('Şimdi geç')),
                  ]else...[
                    const SizedBox(height:10),
                    OutlinedButton(onPressed:widget.onReplay,child:const Text('Tekrar izle')),
                  ]
                ])))),
            ));
          }),''')
# overlay above controls instead: position block was inserted before AnimatedOpacity, needs move AFTER controls otherwise controls cover it
start=s.index('          ValueListenableBuilder<bool>(valueListenable:widget.completed')
end=s.index('          AnimatedOpacity(opacity:showing?',start)
overlay=s[start:end]
s=s[:start]+s[end:]
needle='''            ]))),
        ]))));'''
if needle not in s: print('WARNING overlay insertion target not found')
else:s=s.replace(needle,'''            ]))),
'''+overlay+'''        ]))));''',1)
# fullscreen props
s=s.replace('''  final VideoPlayerController controller;
  const _FullscreenVideo({required this.controller});''','''  final VideoPlayerController controller;
  final ValueNotifier<bool> completed;
  final ValueNotifier<int?> countdown;
  final String? nextLessonTitle;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  const _FullscreenVideo({required this.controller,required this.completed,
    required this.countdown,required this.onNext,required this.onReplay,
    this.nextLessonTitle});''')
s=s.replace('''Center(child:_PlayerSurface(controller:widget.controller,fullscreen:true)),''','''Center(child:_PlayerSurface(controller:widget.controller,fullscreen:true,
        completed:widget.completed,countdown:widget.countdown,
        nextLessonTitle:widget.nextLessonTitle,onNext:widget.onNext,onReplay:widget.onReplay)),''')
p.write_text(s)
print('patched length',len(s))
