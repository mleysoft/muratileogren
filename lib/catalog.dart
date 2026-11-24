import 'dart:async';
import 'package:flutter/material.dart';
import 'components.dart';
import 'store.dart';
import 'theme.dart';
import 'lesson.dart';

class CatalogScreen extends StatefulWidget {
  final AcademyStore store;
  const CatalogScreen({super.key,required this.store});
  @override State<CatalogScreen> createState()=>_CatalogScreenState();
}
class _CatalogScreenState extends State<CatalogScreen>{
  final ctl=TextEditingController();
  Timer? debounce;
  List<Map<String,dynamic>> results=[];
  bool searching=false;
  @override void dispose(){debounce?.cancel();ctl.dispose();super.dispose();}
  void search(String v){debounce?.cancel();
    if(v.trim().isEmpty){setState((){searching=false;results=[];});return;}
    debounce=Timer(const Duration(milliseconds:380),()async{
      setState(()=>searching=true);
      try {final data=await widget.store.api.search(v.trim());if(mounted && ctl.text.trim()==v.trim())setState(()=>results=data.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList());}
      catch(e){if(mounted)showFailure(context,e);}
    });
  }
  @override Widget build(BuildContext context){
    final store=widget.store;
    return Scaffold(appBar:AppBar(title:const Text('Eğitimler',style:TextStyle(fontWeight:FontWeight.w900))),
      body:ListView(padding:const EdgeInsets.fromLTRB(20,8,20,38),children:[
      const Eyebrow('Kendine yatırım yap'),const SizedBox(height:9),
      Text('Bir sonraki becerin\nburada başlıyor.',style:Theme.of(context).textTheme.headlineLarge),const SizedBox(height:16),
      TextField(controller:ctl,onChanged:search,decoration:const InputDecoration(prefixIcon:Icon(Icons.search_rounded),hintText:'Ders, formül veya konu ara...')),
      const SizedBox(height:22),
      if(searching)...[
        SectionHeading('Arama sonuçları',description:'${results.length} ders bulundu'),const SizedBox(height:14),
        if(results.isEmpty)const StateMessage('Aradığın kelimeyle eşleşen ders bulunamadı.',icon:Icons.search_off),
        ...results.map((l)=>Padding(padding:const EdgeInsets.only(bottom:10),child:LessonTile(data:l,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LessonScreen(store:store,id:asInt(l['id']))))))),
      ] else ...[
        SectionHeading('Tüm eğitimler',description:'İşinde kullanacağın pratik bilgiler.'),const SizedBox(height:15),
        ...store.categories.map((c)=>Padding(padding:const EdgeInsets.only(bottom:13),child:CourseCard(data:c,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CategoryScreen(store:store,id:asInt(c['id']))))))),
      ]
    ]));
  }
}

class CategoryScreen extends StatefulWidget {
  final AcademyStore store;final int id;
  const CategoryScreen({super.key,required this.store,required this.id});
  @override State<CategoryScreen> createState()=>_CategoryScreenState();
}
class _CategoryScreenState extends State<CategoryScreen>{
  late Future<Map<String,dynamic>> future;
  @override void initState(){super.initState();future=widget.store.api.category(widget.id);}
  void reload()=>setState(()=>future=widget.store.api.category(widget.id));
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Eğitim programı',style:TextStyle(fontWeight:FontWeight.w800))),
    body:FutureBuilder<Map<String,dynamic>>(future:future,builder:(ctx,s){
      if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return StateMessage(s.error.toString(),retry:reload,icon:Icons.wifi_off);
      final data=s.data!;final category=Map<String,dynamic>.from(data['category']);
      final lessons=(data['lessons'] as List).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
      final sections=<String,List<Map<String,dynamic>>>{};
      for(final l in lessons) sections.putIfAbsent(str(l['section'],'Dersler'),()=>[]).add(l);
      final total=lessons.length;final done=lessons.where((l)=>l['completed']==true).length;
      return RefreshIndicator(onRefresh:()async{reload();await future;},child:ListView(padding:const EdgeInsets.fromLTRB(20,8,20,40),children:[
        Container(padding:const EdgeInsets.fromLTRB(21,24,21,24),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:soft)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Eyebrow('Uygulamalı eğitim programı'),const SizedBox(height:13),
          Text(str(category['title']),style:Theme.of(context).textTheme.headlineLarge),const SizedBox(height:13),
          Text(str(category['summary']),style:const TextStyle(color:muted,height:1.6,fontSize:13)),const SizedBox(height:17),
          Wrap(spacing:8,runSpacing:8,children:[SoftBadge('$total ders'),SoftBadge(durationText(category['duration_sec'])),
            if(asInt(category['rating_count'])>0)SoftBadge('${asDouble(category['rating']).toStringAsFixed(1)} ★ öğrenci değerlendirmesi')]),
        ])),
        if(widget.store.signedIn && total>0)...[const SizedBox(height:23),
          Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(19),border:Border.all(color:soft)),
          child:Column(children:[Row(children:[const Icon(Icons.school_outlined,color:forest),const SizedBox(width:8),const Text('Eğitim ilerlemen',style:TextStyle(fontWeight:FontWeight.w800)),const Spacer(),Text('$done / $total',style:const TextStyle(fontWeight:FontWeight.w800))]),const SizedBox(height:13),ClipRRect(borderRadius:BorderRadius.circular(9),child:LinearProgressIndicator(value:done/total,minHeight:8,color:forest,backgroundColor:soft))])),
        ],
        const SizedBox(height:28),const Eyebrow('Ders akışı'),const SizedBox(height:13),for(final entry in sections.entries)...[
          Padding(padding:const EdgeInsets.only(bottom:12),child:Text(entry.key,style:Theme.of(context).textTheme.titleLarge)),
          for(final l in entry.value)Padding(padding:const EdgeInsets.only(bottom:9),child:LessonTile(data:l,index:lessons.indexOf(l),onTap:()async{
            await Navigator.push(context,MaterialPageRoute(builder:(_)=>LessonScreen(store:widget.store,id:asInt(l['id']))));
            if(mounted)reload();
          })),const SizedBox(height:16),
        ]
      ]));
    }));
}
