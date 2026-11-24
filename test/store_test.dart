import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:murat_ile_ogren/main.dart';
import 'package:murat_ile_ogren/theme.dart';
import 'package:murat_ile_ogren/api.dart';
import 'package:murat_ile_ogren/store.dart';

class FakeAcademyApi extends AcademyApi {
  @override
  Future<void> logout() async {}

  @override
  Future<Map<String,dynamic>> bootstrap() async => {
    'user':null,
    'categories':<dynamic>[],
    'latest_lessons':<dynamic>[],
    'continue':<dynamic>[],
  };
}

void main() {
  test('Çıkış kullanıcı durumunu hemen temizler', () async {
    final api=FakeAcademyApi();
    final store=AcademyStore(api);
    store.user=<String,dynamic>{'id':1,'name':'Deneme'};
    expect(store.signedIn,isTrue);
    await store.logout();
    expect(store.signedIn,isFalse);
    expect(store.user,isNull);
    await Future<void>.delayed(Duration.zero);
    store.dispose();
  });
  testWidgets('Profil sekmesi çıkış sonrasında yeniden çizilir', (tester) async {
    final store=AcademyStore(FakeAcademyApi());
    store.user=<String,dynamic>{
      'id':1,'name':'Deneme Kullanıcı','email':'deneme@example.com',
      'subscription':<String,dynamic>{'active':false},
    };
    await tester.pumpWidget(MaterialApp(theme:academyTheme(),
      home:AcademyShell(store:store)));
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('Merhaba, Deneme.'),findsOneWidget);
    await store.logout();
    await tester.pumpAndSettle();
    expect(find.text('Merhaba, Deneme.'),findsNothing);
    expect(find.text('Ücretsiz hesap oluştur'),findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

}
