MURAT ILE OGREN - CODEMAGIC IOS POST-CLONE HATA DUZELTMESI

Hata: Could not locate Flutter plugin registration in AppDelegate.swift
Neden: Flutter 3.41+ UIScene template; plugin registration didInitializeImplicitFlutterEngine icinde.

Kurulum:
1. ZIP'in icindeki scripts klasorunu C:\Muratileogren\scripts uzerine kopyalayin.
2. GitHub Desktop > Commit to main > Push origin.
3. Codemagic Post-clone komutunu DEGISTIRMEYIN:
   #!/bin/bash
   set -e
   bash scripts/codemagic_post_clone_ios.sh
4. Start new build > main > Default Workflow.

Bu dosya, Firebase APNs yetkilendirmesine veya Flutter uygulama koduna dokunmaz.
Yeni Flutter UIScene ve eski AppDelegate yapilarini destekler.

NOT: iOS cihaz ve Codemagic derlemesi burada yapilamadi.
