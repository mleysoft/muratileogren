import 'package:flutter/material.dart';
import 'components.dart';
import 'store.dart';
import 'theme.dart';
import 'catalog.dart';
import 'lesson.dart';
import 'account.dart';

class HomeScreen extends StatelessWidget {
  final AcademyStore store;
  const HomeScreen({super.key,required this.store});
  @override Widget build(BuildContext context){
    final w=MediaQuery.sizeOf(context).width;
    return RefreshIndicator(onRefresh:store.reload,child:ListView(padding:const EdgeInsets.fromLTRB(18,17,18,44),children:[
      const Eyebrow('MG Akademi  /  Dijital öğrenme'),const SizedBox(height:14),
      _Hero(store:store),const SizedBox(height:20),
      Row(children:[_InfoStat('${store.categories.length}','Eğitim programı'),const SizedBox(width:9),const _InfoStat('2 / hafta','Yeni eğitim'),const SizedBox(width:9),const _InfoStat('7/24','Öğrenme')]),
      if(store.continuing.isNotEmpty)...[
        const SizedBox(height:32),SectionHeading('Kaldığın yerden devam et',description:'Son izlediğin dersleri tamamla.'),const SizedBox(height:15),
        ...store.continuing.take(3).map((l)=>Padding(padding:const EdgeInsets.only(bottom:10),child:LessonTile(data:l,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LessonScreen(store:store,id:asInt(l['id']))))))),
      ],
      const SizedBox(height:33),SectionHeading('Eğitim programları',description:'Gerçek işler için uygulamalı dersler.',
        trailing:TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CatalogScreen(store:store))),child:const Text('Tümü  ↗'))),
      const SizedBox(height:16),if(store.categories.isEmpty)const StateMessage('Henüz eğitim bulunamadı.'),
      LayoutBuilder(builder:(ctx,c){final columns=c.maxWidth>670?2:1;return GridView.builder(physics:const NeverScrollableScrollPhysics(),shrinkWrap:true,
        itemCount:store.categories.length,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:columns,crossAxisSpacing:13,mainAxisSpacing:13,mainAxisExtent:325),
        itemBuilder:(ctx,i)=>CourseCard(data:store.categories[i],onTap:()=>Navigator.push(ctx,MaterialPageRoute(builder:(_)=>CategoryScreen(store:store,id:asInt(store.categories[i]['id']))))));}),
      const SizedBox(height:35),SectionHeading('En yeni dersler',description:'Her hafta yeni bir beceri.'),const SizedBox(height:15),
      ...store.latest.take(4).map((l)=>Padding(padding:const EdgeInsets.only(bottom:10),child:LessonTile(data:l,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LessonScreen(store:store,id:asInt(l['id']))))))),
      const SizedBox(height:22),const _PromiseCard(),
      if(!store.signedIn)...[const SizedBox(height:19),OutlinedButton.icon(
        onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LoginScreen(store:store))),
        icon:const Icon(Icons.person_outline_rounded),label:const Text('Ücretsiz hesabınla giriş yap'))],
      const SizedBox(height:12),Center(child:Text('MG İLE ÖĞREN  •  muratileogren.com',style:TextStyle(color:muted.withValues(alpha:.7),fontSize:10,letterSpacing:.8,fontWeight:FontWeight.w700))),
    ]));
  }
}
class _Hero extends StatelessWidget {
  final AcademyStore store;
  const _Hero({required this.store});
  @override Widget build(BuildContext context){final width=MediaQuery.sizeOf(context).width;
    return Container(width:double.infinity,decoration:BoxDecoration(color:Colors.white,border:Border.all(color:soft),borderRadius:BorderRadius.circular(26)),
      child:ClipRRect(borderRadius:BorderRadius.circular(26),child:Stack(children:[
        Positioned(right:-82,top:-80,child:Container(width:215,height:215,decoration:BoxDecoration(color:lime.withValues(alpha:.23),shape:BoxShape.circle))),
        Positioned(right:-60,bottom:-110,child:Container(width:220,height:220,decoration:BoxDecoration(border:Border.all(color:forest.withValues(alpha:.13),width:27),shape:BoxShape.circle))),
        Padding(padding:const EdgeInsets.fromLTRB(23,26,20,26),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:Color(0xFFF0F8D9),borderRadius:BorderRadius.circular(24)),
            child:const Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.bolt_rounded,color:forest,size:16),SizedBox(width:6),Text('HER HAFTA 2 YENİ EĞİTİM',style:TextStyle(color:forest,fontWeight:FontWeight.w900,letterSpacing:.55,fontSize:10))])),
          const SizedBox(height:25),          Text(
            store.signedIn
                ? 'Gelişmeye\nkaldığın yerden\ndevam et.'
                : 'Bilgini artır.\nİşini kolaylaştır.\nFark yarat.',
            style: TextStyle(
              color: ink,
              fontWeight: FontWeight.w900,
              fontSize: width > 450 ? 39 : 33,
              height: 1.06,
              letterSpacing: -1.35,
            ),
          ),
          const SizedBox(height:17),ConstrainedBox(constraints:const BoxConstraints(maxWidth:310),child:const Text(
            'Excel, Word, PowerPoint ve bilgisayar becerilerini gerçek örneklerle öğren. Kendi hızında ilerle.',
            style:TextStyle(color:muted,fontSize:13,height:1.55))),
          const SizedBox(height:23),FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CatalogScreen(store:store))),
            icon:const Icon(Icons.arrow_forward_rounded,size:19),label:const Text('Eğitimleri keşfet')),
          const SizedBox(height:25),const Row(children:[Icon(Icons.check_circle_rounded,color:forest,size:15),SizedBox(width:6),Text('Uygulamalı dersler',style:TextStyle(fontSize:11,color:forest,fontWeight:FontWeight.w700)),SizedBox(width:14),Icon(Icons.check_circle_rounded,color:forest,size:15),SizedBox(width:6),Text('Kalıcı ilerleme',style:TextStyle(fontSize:11,color:forest,fontWeight:FontWeight.w700))]),
        ])),
      ])));
  }
}
class _InfoStat extends StatelessWidget {
  final String value,label;const _InfoStat(this.value,this.label);
  @override Widget build(BuildContext context)=>Expanded(child:Container(padding:const EdgeInsets.symmetric(vertical:15,horizontal:6),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:soft)),
    child:Column(children:[Text(value,maxLines:1,style:const TextStyle(color:forest,fontWeight:FontWeight.w900,fontSize:15)),const SizedBox(height:3),Text(label,maxLines:1,style:const TextStyle(color:muted,fontSize:10))])));
}
class _PromiseCard extends StatelessWidget {
  const _PromiseCard();
  @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(23),decoration:BoxDecoration(color:ink,borderRadius:BorderRadius.circular(23)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('BİZİM YÖNTEMİMİZ',style:TextStyle(color:lime,letterSpacing:1.5,fontWeight:FontWeight.w900,fontSize:10)),
    const SizedBox(height:12),const Text('İzle. Uygula. Öğren.',style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w900)),const SizedBox(height:16),
    for(final item in [('01','Gerçek iş senaryolarıyla öğren'),('02','Ders dosyalarıyla kendin dene'),('03','Tamamladığın dersleri takip et')])Padding(padding:const EdgeInsets.only(bottom:13),child:Row(children:[
      Container(width:34,height:34,alignment:Alignment.center,decoration:BoxDecoration(color:lime.withValues(alpha:.15),borderRadius:BorderRadius.circular(11)),child:Text(item.$1,style:const TextStyle(fontWeight:FontWeight.w900,color:lime,fontSize:11))),
      const SizedBox(width:12),Expanded(child:Text(item.$2,style:const TextStyle(color:Colors.white,fontSize:13,fontWeight:FontWeight.w600))),
    ]))]));
}
