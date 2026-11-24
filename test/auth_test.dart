import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murat_ile_ogren/account.dart';
import 'package:murat_ile_ogren/api.dart';
import 'package:murat_ile_ogren/store.dart';
import 'package:murat_ile_ogren/theme.dart';

void main() {
  testWidgets('Giriş ekranı profesyonel yerleşim ve doğrulama', (tester) async {
    final store=AcademyStore(AcademyApi());
    await tester.pumpWidget(MaterialApp(theme:academyTheme(),
      home:LoginScreen(store:store)));
    expect(find.text('Tekrar hoş geldin'),findsOneWidget);
    expect(find.byKey(const ValueKey('login-email')),findsOneWidget);
    expect(find.byKey(const ValueKey('login-password')),findsOneWidget);
    expect(tester.takeException(),isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('login-submit')));
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();
    expect(find.text('Geçerli e-posta adresi yaz'),findsOneWidget);
    expect(find.text('Şifreni gir'),findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('Girişten kayıt ekranına geçiş ve sözleşme erişimi', (tester) async {
    final store=AcademyStore(AcademyApi());
    await tester.pumpWidget(MaterialApp(theme:academyTheme(),
      home:LoginScreen(store:store)));
    await tester.tap(find.text('Hesap oluştur'));
    await tester.pumpAndSettle();
    expect(find.text('Ücretsiz hesap oluştur'),findsOneWidget);
    expect(find.byKey(const ValueKey('register-name')),findsOneWidget);
    expect(find.byKey(const ValueKey('register-email')),findsOneWidget);
    expect(find.byKey(const ValueKey('register-terms')),findsOneWidget);
    await tester.ensureVisible(find.text('Koşulları uygulama içinde oku'));
    await tester.pump();
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}
