import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murat_ile_ogren/theme.dart';
import 'package:murat_ile_ogren/components.dart';

void main() {
  testWidgets('MG marka başlığı ve kimliği görünür', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: academyTheme(),
      home: const Scaffold(body: Center(child: LogoWordmark())),
    ));
    expect(find.text('MG İle Öğren'), findsOneWidget);
    expect(find.text('Dijital Eğitim Akademisi'), findsOneWidget);
  });

  testWidgets('Ders tamamlandı bilgisi', (tester) async {
    final demo=<String,dynamic>{
      'id':1,'title':'Excel Formülleri','duration_sec':240,
      'can_watch':true,'completed':true,'is_free':true,
      'rating_count':2,'rating':4.5,
    };
    await tester.pumpWidget(MaterialApp(
      theme:academyTheme(),
      home:Scaffold(body:LessonTile(data:demo,onTap:(){})),
    ));
    expect(find.text('Tamamlandı'), findsOneWidget);
    expect(find.text('Ücretsiz'), findsOneWidget);
  });

  testWidgets('Eğitim kartı dikey ListView içinde yerleşim hatası vermez', (tester) async {
    final course=<String,dynamic>{
      'id':7,
      'title':'Excel’de Biçimlendirme ve Veri Temizleme',
      'summary':'Pratik uygulamalarla gerçek iş senaryolarını öğren.',
      'color':'#1F3864','cover':'',
      'lesson_count':12,'completed':3,
      'rating_count':18,'rating':4.8,
    };
    await tester.pumpWidget(MaterialApp(
      theme:academyTheme(),
      home:Scaffold(body:ListView(children:[
        CourseCard(data:course,onTap:(){}),
      ])),
    ));
    await tester.pump();
    expect(tester.takeException(),isNull);
    expect(find.text('Excel’de Biçimlendirme ve Veri Temizleme'),findsOneWidget);
  });

  test('Süre biçimleme', () {
    expect(durationText(600),'10 dk');
    expect(durationText(3600),'1 sa 0 dk');
  });
}
