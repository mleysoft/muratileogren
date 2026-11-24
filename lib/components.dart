import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'theme.dart';

String str(dynamic v,[String fallback=''])=>v?.toString()??fallback;
int asInt(dynamic v)=>int.tryParse(str(v))??0;
double asDouble(dynamic v)=>double.tryParse(str(v))??0;
String durationText(dynamic v){final s=asInt(v);if(s<1)return 'Kısa ders';if(s>=3600)return '${s~/3600} sa ${(s%3600)~/60} dk';return '${s~/60} dk';}
String trCount(dynamic v)=>NumberFormat.decimalPattern('tr_TR').format(asInt(v));

class LogoWordmark extends StatelessWidget {
  final bool small;
  const LogoWordmark({super.key,this.small=false});
  @override Widget build(BuildContext context)=>Row(mainAxisSize:MainAxisSize.min,children:[
    ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.asset('assets/logo.png',width:small?33:40,height:small?33:40)),
    const SizedBox(width:10),Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
      Text('Murat İle Öğren',style:TextStyle(fontSize:small?15:17,fontWeight:FontWeight.w800,letterSpacing:-.5,color:ink)),
      if(!small) const Text('Dijital Eğitim Akademisi',style:TextStyle(color:muted,fontSize:10,fontWeight:FontWeight.w600,letterSpacing:.4)),
    ]),
  ]);
}
class Eyebrow extends StatelessWidget {
  final String label;
  const Eyebrow(this.label,{super.key});
  @override Widget build(BuildContext context)=>Text(label.toUpperCase(),style:const TextStyle(color:forest,fontSize:11,fontWeight:FontWeight.w800,letterSpacing:1.5));
}
class SectionHeading extends StatelessWidget {
  final String title,description;
  final Widget? trailing;
  const SectionHeading(this.title,{super.key,this.description='',this.trailing});
  @override Widget build(BuildContext context)=>Row(crossAxisAlignment:CrossAxisAlignment.center,children:[
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title,style:Theme.of(context).textTheme.headlineMedium),
      if(description.isNotEmpty)...[const SizedBox(height:5),Text(description,style:const TextStyle(color:muted,fontSize:13))]
    ])), if(trailing!=null) trailing!,
  ]);
}
class SoftBadge extends StatelessWidget {
  final String text;final Color color;
  const SoftBadge(this.text,{super.key,this.color=forest});
  @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
    decoration:BoxDecoration(color:color.withValues(alpha:.09),borderRadius:BorderRadius.circular(9)),
    child:Text(text,style:TextStyle(color:color,fontWeight:FontWeight.w800,fontSize:10)));
}
class RatingRow extends StatelessWidget {
  final dynamic rating,count;
  const RatingRow({super.key,required this.rating,required this.count});
  @override Widget build(BuildContext context){if(asInt(count)<1)return const SizedBox.shrink();
    return Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.star_rounded,color:Color(0xFFF6AD3D),size:17),
      const SizedBox(width:3),Text(asDouble(rating).toStringAsFixed(1).replaceAll('.',','),style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800)),
      const SizedBox(width:5),Text('(${trCount(count)})',style:const TextStyle(color:muted,fontSize:11))]);}
}
class LessonTile extends StatelessWidget {
  final Map<String,dynamic> data;
  final VoidCallback onTap;
  final int? index;
  const LessonTile({super.key,required this.data,required this.onTap,this.index});
  @override Widget build(BuildContext context){
    final done=data['completed']==true,locked=data['can_watch']==false;
    return Material(color:Colors.white,borderRadius:BorderRadius.circular(18),child:InkWell(borderRadius:BorderRadius.circular(18),onTap:onTap,
    child:Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),border:Border.all(color:soft)),
      child:Row(children:[
        Container(width:45,height:45,alignment:Alignment.center,decoration:BoxDecoration(color:done?const Color(0xFFE7F8E9):paper,borderRadius:BorderRadius.circular(14)),
          child:done?const Icon(Icons.check_circle,color:forest,size:23):Text(index==null?'▶':(index!+1).toString().padLeft(2,'0'),style:const TextStyle(fontWeight:FontWeight.w800,color:forest))),
        const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(str(data['title']),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:14,color:ink)),
          const SizedBox(height:6),Wrap(spacing:9,runSpacing:4,children:[
            Text(durationText(data['duration_sec']),style:const TextStyle(color:muted,fontSize:11)),
            if(data['is_free']==true) const Text('Ücretsiz',style:TextStyle(color:forest,fontSize:11,fontWeight:FontWeight.w700)),
            if(done) const Text('Tamamlandı',style:TextStyle(color:forest,fontSize:11,fontWeight:FontWeight.w700)),
            if(asInt(data['rating_count'])>0) RatingRow(rating:data['rating'],count:data['rating_count']),
          ])
        ])),Icon(locked?Icons.lock_outline_rounded:Icons.chevron_right_rounded,size:22,color:muted)
      ]))));
  }
}
class CourseCard extends StatelessWidget {
  final Map<String,dynamic> data;
  final VoidCallback onTap;
  const CourseCard({super.key,required this.data,required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent=Color(int.tryParse(str(data['color']).replaceAll('#','0xff'))??0xFF246747);
    final title=str(data['title']);
    final cover=str(data['cover']);
    final n=asInt(data['lesson_count']);
    final done=asInt(data['completed']);
    return Material(
      color:Colors.white,
      borderRadius:BorderRadius.circular(24),
      clipBehavior:Clip.antiAlias,
      child:InkWell(
        onTap:onTap,
        child:Container(
          decoration:BoxDecoration(
            border:Border.all(color:soft),
            borderRadius:BorderRadius.circular(24),
          ),
          child:Column(
            mainAxisSize:MainAxisSize.min,
            crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              ClipRRect(
                borderRadius:const BorderRadius.vertical(top:Radius.circular(23)),
                child:Container(
                  height:111,
                  width:double.infinity,
                  decoration:BoxDecoration(
                    gradient:LinearGradient(
                      begin:Alignment.topLeft,
                      end:Alignment.bottomRight,
                      colors:[accent,accent.withValues(alpha:.88),ink],
                    ),
                  ),
                  child:Stack(children:[
                    if(cover.startsWith('https://'))
                      Positioned.fill(child:Image.network(cover,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox.shrink())),
                    Positioned(right:-35,top:-56,child:Container(width:185,height:185,decoration:BoxDecoration(
                      shape:BoxShape.circle,border:Border.all(color:Colors.white.withValues(alpha:.13),width:24),
                    ))),
                    Positioned(left:18,top:17,child:Container(
                      padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),
                      decoration:BoxDecoration(color:Colors.white.withValues(alpha:.18),borderRadius:BorderRadius.circular(25)),
                      child:const Text('UYGULAMALI EĞİTİM',style:TextStyle(fontSize:9,fontWeight:FontWeight.w900,color:Colors.white,letterSpacing:.7)),
                    )),
                    Positioned(right:18,bottom:13,child:Container(
                      width:56,height:56,
                      decoration:BoxDecoration(color:Colors.white.withValues(alpha:.18),borderRadius:BorderRadius.circular(18)),
                      child:Icon(_courseIcon(title),size:31,color:Colors.white),
                    )),
                  ]),
                ),
              ),
              // The course card must also work inside a vertical ListView,
              // where the available height is unbounded. No Expanded/Spacer here.
              Padding(
                padding:const EdgeInsets.fromLTRB(16,15,16,14),
                child:Column(
                  mainAxisSize:MainAxisSize.min,
                  crossAxisAlignment:CrossAxisAlignment.start,
                  children:[
                    Text(title,maxLines:2,overflow:TextOverflow.ellipsis,
                      style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900,color:ink,height:1.18)),
                    const SizedBox(height:6),
                    Text(str(data['summary']),maxLines:2,overflow:TextOverflow.ellipsis,
                      style:const TextStyle(color:muted,fontSize:11.5,height:1.4)),
                    const SizedBox(height:17),
                    const Divider(height:1,color:soft),
                    const SizedBox(height:12),
                    Row(children:[
                      const Icon(Icons.play_circle_outline_rounded,color:forest,size:16),
                      const SizedBox(width:5),
                      Text('$n ders',style:const TextStyle(color:forest,fontSize:11.5,fontWeight:FontWeight.w800)),
                      const Spacer(),
                      RatingRow(rating:data['rating'],count:data['rating_count']),
                      const SizedBox(width:5),
                      const Icon(Icons.arrow_forward_rounded,color:forest,size:18),
                    ]),
                    if(done>0 && n>0)...[
                      const SizedBox(height:9),
                      ClipRRect(borderRadius:BorderRadius.circular(5),
                        child:LinearProgressIndicator(
                          value:(done/n).clamp(0.0,1.0),minHeight:5,color:forest,backgroundColor:soft)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
IconData _courseIcon(String text){final s=text.toLowerCase();if(s.contains('excel'))return Icons.grid_on_rounded;if(s.contains('word'))return Icons.description_outlined;if(s.contains('powerpoint'))return Icons.slideshow_outlined;return Icons.computer_outlined;}

class StateMessage extends StatelessWidget {
  final String text;final VoidCallback? retry;final IconData icon;
  const StateMessage(this.text,{super.key,this.retry,this.icon=Icons.inbox_outlined});
  @override Widget build(BuildContext context)=>Center(child:Padding(padding:const EdgeInsets.all(32),child:Column(mainAxisSize:MainAxisSize.min,children:[
    Icon(icon,size:48,color:forest),const SizedBox(height:16),Text(text,textAlign:TextAlign.center,style:const TextStyle(fontSize:14,height:1.5,color:muted)),
    if(retry!=null)...[const SizedBox(height:20),OutlinedButton.icon(onPressed:retry,icon:const Icon(Icons.refresh),label:const Text('Yeniden dene'))]
  ])));
}
void showFailure(BuildContext context,Object e){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString()),behavior:SnackBarBehavior.floating,backgroundColor:ink));}

class AppPage extends StatelessWidget {
  final String title;final Widget child;
  const AppPage({super.key,required this.title,required this.child});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800))),body:child);
}
