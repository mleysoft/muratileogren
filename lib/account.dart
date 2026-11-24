import 'package:flutter/material.dart';
import 'in_app_browser.dart';
import 'api.dart';
import 'components.dart';
import 'config.dart';
import 'store.dart';
import 'theme.dart';
import 'lesson.dart';

/// Auth pages share their visual identity but keep Flutter-native input fields.
/// No WebView is involved in logging in, registering or saving credentials.
class _AuthShell extends StatelessWidget {
  final bool registering;
  final Widget form;
  final AcademyStore store;
  const _AuthShell({required this.registering,required this.form,required this.store});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor:paper,
    body:SafeArea(child:Stack(children:[
      Positioned(top:-135,right:-145,child:IgnorePointer(child:Container(
        width:310,height:310,decoration:BoxDecoration(
          color:lime.withValues(alpha:.11),shape:BoxShape.circle)))),
      Positioned(bottom:-110,left:-155,child:IgnorePointer(child:Container(
        width:300,height:300,decoration:BoxDecoration(
          color:forest.withValues(alpha:.045),shape:BoxShape.circle)))),
      SingleChildScrollView(
        keyboardDismissBehavior:ScrollViewKeyboardDismissBehavior.onDrag,
        padding:const EdgeInsets.fromLTRB(20,12,20,35),
        child:Center(child:ConstrainedBox(
          constraints:const BoxConstraints(maxWidth:480),
          child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            Row(children:[
              IconButton.filledTonal(
                tooltip:'Geri',
                onPressed:()=>Navigator.of(context).maybePop(),
                icon:const Icon(Icons.arrow_back_rounded,size:20),
                style:IconButton.styleFrom(backgroundColor:Colors.white,
                  side:const BorderSide(color:soft))),
              const SizedBox(width:9),
              const Expanded(child:LogoWordmark(small:true)),
              if(MediaQuery.sizeOf(context).width>=380)
                Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),
                decoration:BoxDecoration(color:lime.withValues(alpha:.20),
                  borderRadius:BorderRadius.circular(20)),
                child:const Row(mainAxisSize:MainAxisSize.min,children:[
                  Icon(Icons.verified_user_outlined,color:forest,size:14),
                  SizedBox(width:5),Text('Güvenli giriş',style:TextStyle(
                    color:forest,fontSize:10,fontWeight:FontWeight.w800))])),
            ]),
            const SizedBox(height:24),
            _AuthHero(registering:registering),
            const SizedBox(height:20),
            _AuthModeSwitch(registering:registering,store:store),
            const SizedBox(height:13),
            Container(
              padding:const EdgeInsets.fromLTRB(20,23,20,23),
              decoration:BoxDecoration(color:Colors.white,
                border:Border.all(color:soft),
                borderRadius:BorderRadius.circular(23),
                boxShadow:[BoxShadow(color:ink.withValues(alpha:.04),
                  blurRadius:26,offset:const Offset(0,9))]),
              child:form,
            ),
            const SizedBox(height:18),
            const Row(mainAxisAlignment:MainAxisAlignment.center,children:[
              Icon(Icons.sync_rounded,color:muted,size:15),
              SizedBox(width:7),
              Flexible(child:Text('Tek hesap, web ve mobilde ortak ilerleme',
                textAlign:TextAlign.center,style:TextStyle(color:muted,
                  fontSize:11.5,fontWeight:FontWeight.w600))),
            ]),
          ]),
        )),
      ),
    ])),
  );
}

class _AuthHero extends StatelessWidget {
  final bool registering;
  const _AuthHero({required this.registering});
  @override
  Widget build(BuildContext context) => Container(
    padding:const EdgeInsets.fromLTRB(21,23,17,23),
    decoration:BoxDecoration(
      gradient:const LinearGradient(colors:[Color(0xFF163629),Color(0xFF254E39)],
        begin:Alignment.topLeft,end:Alignment.bottomRight),
      borderRadius:BorderRadius.circular(25)),
    child:ClipRect(child:Row(children:[
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),
          decoration:BoxDecoration(color:lime.withValues(alpha:.16),
            borderRadius:BorderRadius.circular(30)),
          child:const Text('MURAT İLE ÖĞREN  /  DİJİTAL AKADEMİ',
            style:TextStyle(color:lime,fontSize:9,fontWeight:FontWeight.w800,
              letterSpacing:1.1))),
        const SizedBox(height:16),
        Text(registering?'Yeni bir beceriye\nmerhaba de.':'Kaldığın yerden\ndevam et.',
          style:const TextStyle(color:Colors.white,fontSize:25,
            fontWeight:FontWeight.w900,height:1.13,letterSpacing:-.7)),
        const SizedBox(height:10),
        Text(registering
          ? 'Excel’den bilgisayar becerilerine, gelişimin tek yerde.'
          : 'Derslerin, notların ve ilerlemen seni bekliyor.',
          style:const TextStyle(color:Color(0xFFD1DED5),fontSize:12,height:1.5)),
      ])),
      const SizedBox(width:10),
      SizedBox(width:78,height:118,child:Stack(alignment:Alignment.center,children:[
        Transform.rotate(angle:-.15,child:Container(width:69,height:87,
          decoration:BoxDecoration(color:lime,borderRadius:BorderRadius.circular(17)))),
        Transform.rotate(angle:.13,child:Container(width:65,height:80,
          decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(17)),
          child:const Icon(Icons.auto_stories_rounded,color:forest,size:37))),
        const Positioned(right:0,bottom:5,child:Icon(Icons.stars_rounded,
          color:lime,size:27)),
      ])),
    ])),
  );
}

class _AuthModeSwitch extends StatelessWidget {
  final bool registering;
  final AcademyStore store;
  const _AuthModeSwitch({required this.registering,required this.store});
  @override Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.all(5),
    decoration:BoxDecoration(color:const Color(0xFFE9EFE9),
      borderRadius:BorderRadius.circular(18)),
    child:Row(children:[
      _AuthModeButton(title:'Giriş yap',selected:!registering,onPressed:(){
        if(registering){
          Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
            builder:(_)=>LoginScreen(store:store)));
        }
      }),
      _AuthModeButton(title:'Hesap oluştur',selected:registering,onPressed:(){
        if(!registering){
          Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
            builder:(_)=>RegisterScreen(store:store)));
        }
      }),
    ]),
  );
}

class _AuthModeButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onPressed;
  const _AuthModeButton({required this.title,required this.selected,
    required this.onPressed});
  @override Widget build(BuildContext context)=>Expanded(child:Material(
    color:selected?Colors.white:Colors.transparent,
    borderRadius:BorderRadius.circular(14),
    child:InkWell(borderRadius:BorderRadius.circular(14),onTap:onPressed,
      child:Container(padding:const EdgeInsets.symmetric(vertical:13),
        alignment:Alignment.center,child:Text(title,
          style:TextStyle(fontWeight:FontWeight.w800,fontSize:13,
            color:selected?forest:muted))))));
}

class _AuthLabel extends StatelessWidget {
  final String text;
  const _AuthLabel(this.text);
  @override Widget build(BuildContext context)=>Padding(
    padding:const EdgeInsets.only(bottom:7),child:Text(text,
      style:const TextStyle(color:ink,fontWeight:FontWeight.w800,fontSize:12)),
  );
}

class _AuthInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _AuthInfoRow(this.icon,this.text);
  @override Widget build(BuildContext context)=>Row(children:[
    Icon(icon,size:16,color:forest),const SizedBox(width:7),
    Expanded(child:Text(text,style:const TextStyle(color:muted,
      fontSize:11.5,height:1.5))),
  ]);
}

class LoginScreen extends StatefulWidget {
  final AcademyStore store;
  const LoginScreen({super.key,required this.store});
  @override State<LoginScreen> createState()=>_LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final form=GlobalKey<FormState>();
  final email=TextEditingController(),password=TextEditingController();
  bool loading=false,obscure=true;
  @override void dispose(){email.dispose();password.dispose();super.dispose();}
  Future<void> submit() async {
    if(loading || !(form.currentState?.validate()??false))return;
    FocusScope.of(context).unfocus();
    setState(()=>loading=true);
    try{
      await widget.store.login(email.text.trim(),password.text);
      if(mounted)Navigator.of(context).pop(true);
    }catch(e){if(mounted)showFailure(context,e);}
    finally{if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext context)=>_AuthShell(
    registering:false,store:widget.store,
    form:Form(key:form,child:AutofillGroup(child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Tekrar hoş geldin',style:TextStyle(color:ink,
        fontSize:21,fontWeight:FontWeight.w900,letterSpacing:-.4)),
      const SizedBox(height:5),
      const Text('Hesabınla giriş yap, öğrenmeye devam et.',
        style:TextStyle(color:muted,fontSize:12.5,height:1.4)),
      const SizedBox(height:25),
      const _AuthLabel('E-posta adresin'),
      TextFormField(controller:email,
        key:const ValueKey('login-email'),
        keyboardType:TextInputType.emailAddress,
        textInputAction:TextInputAction.next,
        autofillHints:const [AutofillHints.email],
        decoration:const InputDecoration(hintText:'ornek@eposta.com',
          prefixIcon:Icon(Icons.alternate_email_rounded,size:20)),
        validator:(v)=>RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v??'').trim())
          ?null:'Geçerli e-posta adresi yaz',
      ),
      const SizedBox(height:17),
      const _AuthLabel('Şifren'),
      TextFormField(controller:password,
        key:const ValueKey('login-password'),
        obscureText:obscure,
        textInputAction:TextInputAction.done,
        onFieldSubmitted:(_)=>submit(),
        autofillHints:const [AutofillHints.password],
        decoration:InputDecoration(hintText:'Şifreni gir',
          prefixIcon:const Icon(Icons.lock_outline_rounded,size:20),
          suffixIcon:IconButton(tooltip:obscure?'Şifreyi göster':'Şifreyi gizle',
            onPressed:()=>setState(()=>obscure=!obscure),
            icon:Icon(obscure?Icons.visibility_outlined:Icons.visibility_off_outlined))),
        validator:(v)=>(v??'').isNotEmpty?null:'Şifreni gir',
      ),
      const SizedBox(height:21),
      SizedBox(width:double.infinity,child:FilledButton(
        key:const ValueKey('login-submit'),onPressed:loading?null:submit,
        child:loading
          ?const SizedBox(height:21,width:21,child:CircularProgressIndicator(
              strokeWidth:2.5,color:Colors.white))
          :const Row(mainAxisSize:MainAxisSize.min,children:[
              Text('Giriş yap'),SizedBox(width:9),
              Icon(Icons.arrow_forward_rounded,size:19)]))),
      const SizedBox(height:18),
      const _AuthInfoRow(Icons.verified_user_outlined,
        'Web hesabınla derslerine ve ilerlemene güvenle eriş.'),
    ]))),
  );
}

class RegisterScreen extends StatefulWidget {
  final AcademyStore store;
  const RegisterScreen({super.key,required this.store});
  @override State<RegisterScreen> createState()=>_RegisterScreenState();
}
class _RegisterScreenState extends State<RegisterScreen> {
  final keyForm=GlobalKey<FormState>();
  final name=TextEditingController(),email=TextEditingController(),
      phone=TextEditingController(),pw=TextEditingController();
  bool terms=false,marketing=false,loading=false,obscure=true;
  @override void dispose(){
    for(final c in [name,email,phone,pw]){c.dispose();}
    super.dispose();
  }
  Future<void> submit() async {
    if(loading || !(keyForm.currentState?.validate()??false))return;
    if(!terms){
      showFailure(context,const ApiError('Üyelik koşullarını onaylamalısın.'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(()=>loading=true);
    try{
      await widget.store.register({
        'name':name.text.trim(),'email':email.text.trim(),
        'phone':phone.text.trim(),'password':pw.text,
        'marketing_opt_in':marketing,'terms':true,
      });
      if(mounted)Navigator.of(context).pop(true);
    }catch(e){if(mounted)showFailure(context,e);}
    finally{if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext context)=>_AuthShell(
    registering:true,store:widget.store,
    form:Form(key:keyForm,child:AutofillGroup(child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Ücretsiz hesap oluştur',style:TextStyle(color:ink,
        fontSize:21,fontWeight:FontWeight.w900,letterSpacing:-.4)),
      const SizedBox(height:5),
      const Text('Bir hesap, tüm eğitimlerin için tek başlangıç noktası.',
        style:TextStyle(color:muted,fontSize:12.5,height:1.4)),
      const SizedBox(height:23),
      const _AuthLabel('Adın ve soyadın'),
      TextFormField(controller:name,key:const ValueKey('register-name'),
        textCapitalization:TextCapitalization.words,
        textInputAction:TextInputAction.next,
        autofillHints:const [AutofillHints.name],
        decoration:const InputDecoration(hintText:'Ad Soyad',
          prefixIcon:Icon(Icons.person_outline_rounded,size:20)),
        validator:(v)=>(v??'').trim().length>=3?null:'Ad soyad gerekli'),
      const SizedBox(height:15),
      const _AuthLabel('E-posta adresin'),
      TextFormField(controller:email,key:const ValueKey('register-email'),
        keyboardType:TextInputType.emailAddress,
        textInputAction:TextInputAction.next,
        autofillHints:const [AutofillHints.email],
        decoration:const InputDecoration(hintText:'ornek@eposta.com',
          prefixIcon:Icon(Icons.alternate_email_rounded,size:20)),
        validator:(v)=>RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v??'').trim())
          ?null:'Geçerli e-posta adresi yaz'),
      const SizedBox(height:15),
      const _AuthLabel('Telefon (isteğe bağlı)'),
      TextFormField(controller:phone,key:const ValueKey('register-phone'),
        keyboardType:TextInputType.phone,textInputAction:TextInputAction.next,
        autofillHints:const [AutofillHints.telephoneNumber],
        decoration:const InputDecoration(hintText:'05xx xxx xx xx',
          prefixIcon:Icon(Icons.phone_outlined,size:20))),
      const SizedBox(height:15),
      const _AuthLabel('Şifre oluştur'),
      TextFormField(controller:pw,key:const ValueKey('register-password'),
        obscureText:obscure,textInputAction:TextInputAction.done,
        autofillHints:const [AutofillHints.newPassword],
        decoration:InputDecoration(hintText:'En az 8 karakter',
          prefixIcon:const Icon(Icons.lock_outline_rounded,size:20),
          suffixIcon:IconButton(tooltip:obscure?'Şifreyi göster':'Şifreyi gizle',
            onPressed:()=>setState(()=>obscure=!obscure),
            icon:Icon(obscure?Icons.visibility_outlined:Icons.visibility_off_outlined))),
        validator:(v)=>(v??'').length>=8?null:'En az 8 karakter olmalı'),
      const SizedBox(height:21),
      Container(
        padding:const EdgeInsets.fromLTRB(8,7,12,10),
        decoration:BoxDecoration(color:paper,borderRadius:BorderRadius.circular(15),
          border:Border.all(color:soft)),
        child:Column(children:[
          CheckboxListTile(
            key:const ValueKey('register-terms'),
            value:terms,controlAffinity:ListTileControlAffinity.leading,
            contentPadding:EdgeInsets.zero,dense:true,
            title:const Text('Üyelik koşullarını ve gizlilik politikasını kabul ediyorum.',
              style:TextStyle(color:ink,fontSize:12,fontWeight:FontWeight.w600)),
            onChanged:(v)=>setState(()=>terms=v??false),
          ),
          Padding(padding:const EdgeInsets.only(left:35),
            child:Align(alignment:Alignment.centerLeft,child:TextButton.icon(
              onPressed:()=>Navigator.of(context).push(MaterialPageRoute(
                builder:(_)=>const LegalDocumentsScreen())),
              icon:const Icon(Icons.open_in_new_rounded,size:14),
              label:const Text('Koşulları uygulama içinde oku',
                style:TextStyle(fontSize:11,fontWeight:FontWeight.w800)),
              style:TextButton.styleFrom(padding:const EdgeInsets.symmetric(
                horizontal:7,vertical:3),minimumSize:Size.zero),
            )),
          ),
          const Divider(height:13,color:soft),
          CheckboxListTile(
            key:const ValueKey('register-marketing'),
            value:marketing,controlAffinity:ListTileControlAffinity.leading,
            contentPadding:EdgeInsets.zero,dense:true,
            title:const Text('Yeni eğitim ve indirim duyurularını almak istiyorum (isteğe bağlı).',
              style:TextStyle(color:ink,fontSize:12)),
            onChanged:(v)=>setState(()=>marketing=v??false),
          ),
        ]),
      ),
      const SizedBox(height:20),
      SizedBox(width:double.infinity,child:FilledButton(
        key:const ValueKey('register-submit'),onPressed:loading?null:submit,
        child:loading
          ?const SizedBox(height:21,width:21,child:CircularProgressIndicator(
              strokeWidth:2.5,color:Colors.white))
          :const Row(mainAxisSize:MainAxisSize.min,children:[
              Text('Hesap oluştur'),SizedBox(width:9),
              Icon(Icons.arrow_forward_rounded,size:19)]))),
      const SizedBox(height:16),
      const _AuthInfoRow(Icons.lock_outline_rounded,
        'Hesap oluşturmak ücretli abonelik satın almak değildir.'),
    ]))),
  );
}

class ProfileScreen extends StatelessWidget{
  final AcademyStore store;const ProfileScreen({super.key,required this.store});
  @override Widget build(BuildContext context){final u=store.user;
    if(u==null)return ListView(padding:const EdgeInsets.all(24),children:[const SizedBox(height:30),const Icon(Icons.person_outline_rounded,size:67,color:forest),const SizedBox(height:17),
      Text('Eğitim yolculuğuna katıl.',textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:12),
      const Text('İlerlemeni kaydet, derslerini bitir ve nerede kaldıysan oradan devam et.',textAlign:TextAlign.center,style:TextStyle(color:muted)),
      const SizedBox(height:26),FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LoginScreen(store:store))),child:const Text('Giriş yap')),
      const SizedBox(height:10),OutlinedButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>RegisterScreen(store:store))),child:const Text('Ücretsiz hesap oluştur'))
    ]);
    final sub=u['subscription'] is Map?Map<String,dynamic>.from(u['subscription']):<String,dynamic>{};
    return RefreshIndicator(onRefresh:store.reload,child:ListView(padding:const EdgeInsets.fromLTRB(20,15,20,45),children:[
      const Eyebrow('Murat İle Öğren Akademi • Üyelik merkezi'),const SizedBox(height:11),
      Text('Merhaba, ${str(u['name']).split(' ').first}.',style:Theme.of(context).textTheme.headlineLarge),const SizedBox(height:9),
      Text(str(u['email']),style:const TextStyle(color:muted,fontSize:13)),const SizedBox(height:25),
      Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:ink,borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Icon(sub['active']==true?Icons.verified_rounded:Icons.schedule,color:lime),const SizedBox(width:9),Text(sub['active']==true?'Aktif abonelik':'Abonelik aktif değil',style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.w800))]),
        const SizedBox(height:12),Text(sub['active']==true?'${asInt(sub['days_left'])} gün erişimin kaldı.':'Aktif üyeliğin olduğunda tüm ücretli derslere erişebilirsin.',style:const TextStyle(color:Colors.white70,fontSize:13)),
        if(sub['end']!=null)...[const SizedBox(height:8),Text('Bitiş: ${str(sub['end']).split(' ').first}',style:const TextStyle(color:lime,fontSize:12))],
      ])),
      const SizedBox(height:22),_ProfileAction(icon:Icons.edit_outlined,title:'Profilimi düzenle',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>EditProfileScreen(store:store)))),
      _ProfileAction(icon:Icons.play_circle_outline,title:'İzleme geçmişi',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MyLearningScreen(store:store)))),
      _ProfileAction(icon:Icons.receipt_long_outlined,title:'Ödeme geçmişi',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PaymentHistoryScreen(store:store)))),
      _ProfileAction(icon:Icons.workspace_premium_outlined,title:'Üyelik durumu ve paketler',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MembershipScreen(store:store)))),
      _ProfileAction(icon:Icons.mail_outline_rounded,title:'E-posta tercihleri',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MarketingScreen(store:store)))),
      _ProfileAction(icon:Icons.delete_outline_rounded,title:'Hesabımı sil',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>DeleteAccountScreen(store:store)))),
      _ProfileAction(icon:Icons.help_outline_rounded,title:'Yardım ve iletişim',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const InAppBrowser(title:'Yardım ve iletişim',path:'/')))),
      const SizedBox(height:21),OutlinedButton.icon(onPressed:() async {
        try {
          await store.logout();
          if(context.mounted){ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content:Text('Oturum kapatıldı.')));
          }
        }catch(e){if(context.mounted)showFailure(context,e);}
      },icon:const Icon(Icons.logout),label:const Text('Çıkış yap')),
      const SizedBox(height:19),const Center(child:Text('MURAT İLE ÖĞREN • v1.2.0',style:TextStyle(color:muted,letterSpacing:1.2,fontSize:10,fontWeight:FontWeight.w700))),
    ]));
  }
}
class _ProfileAction extends StatelessWidget{
  final IconData icon;final String title;final VoidCallback onTap;
  const _ProfileAction({required this.icon,required this.title,required this.onTap});
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:10),child:Material(color:Colors.white,borderRadius:BorderRadius.circular(16),child:InkWell(borderRadius:BorderRadius.circular(16),onTap:onTap,child:Container(
    padding:const EdgeInsets.symmetric(horizontal:15,vertical:16),decoration:BoxDecoration(border:Border.all(color:soft),borderRadius:BorderRadius.circular(16)),
    child:Row(children:[Icon(icon,color:forest,size:21),const SizedBox(width:13),Expanded(child:Text(title,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w700))),const Icon(Icons.chevron_right,color:muted)])))));
}
class EditProfileScreen extends StatefulWidget{
  final AcademyStore store;const EditProfileScreen({super.key,required this.store});
  @override State<EditProfileScreen> createState()=>_EditProfileState();
}
class _EditProfileState extends State<EditProfileScreen>{
  late TextEditingController name,phone;bool saving=false;
  @override void initState(){super.initState();name=TextEditingController(text:str(widget.store.user?['name']));phone=TextEditingController(text:str(widget.store.user?['phone']));}
  @override void dispose(){name.dispose();phone.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>AppPage(title:'Profilimi düzenle',child:ListView(padding:const EdgeInsets.all(24),children:[
    Text('İletişim bilgilerin',style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:22),
    TextField(controller:name,decoration:const InputDecoration(labelText:'Ad soyad')),const SizedBox(height:13),
    TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Telefon')),const SizedBox(height:19),
    FilledButton(onPressed:saving?null:()async{setState(()=>saving=true);try{final u=await widget.store.api.updateProfile(name.text,phone.text);widget.store.refreshUser(u);if(context.mounted)Navigator.pop(context);}catch(e){if(context.mounted)showFailure(context,e);}finally{if(mounted)setState(()=>saving=false);}},child:Text(saving?'Kaydediliyor...':'Değişiklikleri kaydet'))
  ]));
}
class MarketingScreen extends StatefulWidget{
  final AcademyStore store;const MarketingScreen({super.key,required this.store});
  @override State<MarketingScreen> createState()=>_MarketingState();
}
class _MarketingState extends State<MarketingScreen>{late bool enabled;bool saving=false;
  @override void initState(){super.initState();enabled=widget.store.user?['marketing_opt_in']==true;}
  @override Widget build(BuildContext context)=>AppPage(title:'E-posta tercihleri',child:ListView(padding:const EdgeInsets.all(24),children:[
    const Icon(Icons.mark_email_read_outlined,size:45,color:forest),const SizedBox(height:15),Text('İletişim tercihlerim',style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:9),
    const Text('Yeni ders ve kampanya e-postalarını almak istemiyorsan kapatabilirsin.',style:TextStyle(color:muted)),const SizedBox(height:20),
    SwitchListTile(value:enabled,title:const Text('Eğitim ve kampanya duyuruları'),onChanged:(v)=>setState(()=>enabled=v)),
    const SizedBox(height:14),FilledButton(onPressed:saving?null:()async{setState(()=>saving=true);try{await widget.store.api.updateMarketing(enabled);await widget.store.reload();if(context.mounted)Navigator.pop(context);}catch(e){if(context.mounted)showFailure(context,e);}finally{if(mounted)setState(()=>saving=false);}},child:const Text('Tercihimi kaydet'))
  ]));
}
class MyLearningScreen extends StatefulWidget{
  final AcademyStore store;const MyLearningScreen({super.key,required this.store});
  @override State<MyLearningScreen> createState()=>_MyLearningState();
}
class _MyLearningState extends State<MyLearningScreen>{late Future<List<dynamic>> future;
  @override void initState(){super.initState();future=widget.store.api.progress();}
  @override Widget build(BuildContext context)=>AppPage(title:'Derslerim',child:FutureBuilder<List<dynamic>>(future:future,builder:(ctx,s){
    if(!s.hasData && !s.hasError)return const Center(child:CircularProgressIndicator());
    if(s.hasError)return StateMessage(s.error.toString());
    final rows=s.data!.whereType<Map>().map((l)=>Map<String,dynamic>.from(l)).toList();
    return ListView(padding:const EdgeInsets.all(20),children:[SectionHeading('Öğrenme yolculuğum',description:'${rows.where((l)=>l['completed']==true).length} ders tamamladın'),const SizedBox(height:19),
      if(rows.isEmpty)const StateMessage('Henüz bir ders izlemeye başlamadın.'),
      ...rows.map((l)=>Padding(padding:const EdgeInsets.only(bottom:9),child:LessonTile(data:l,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LessonScreen(store:widget.store,id:asInt(l['id'])))))))
    ]);
  }));
}
class PaymentHistoryScreen extends StatefulWidget{
  final AcademyStore store;const PaymentHistoryScreen({super.key,required this.store});
  @override State<PaymentHistoryScreen> createState()=>_PaymentHistoryState();
}
class _PaymentHistoryState extends State<PaymentHistoryScreen>{late Future<List<dynamic>> future;
  @override void initState(){super.initState();future=widget.store.api.payments();}
  @override Widget build(BuildContext context)=>AppPage(title:'Ödemelerim',child:FutureBuilder<List<dynamic>>(future:future,builder:(ctx,s){
    if(!s.hasData && !s.hasError)return const Center(child:CircularProgressIndicator());
    if(s.hasError)return StateMessage(s.error.toString());
    final entries=s.data!.whereType<Map>().toList();
    return ListView(padding:const EdgeInsets.all(20),children:[if(entries.isEmpty)const StateMessage('Henüz ödeme kaydın yok.'),
      for(final p in entries)Card(child:Padding(padding:const EdgeInsets.all(16),child:Row(children:[const Icon(Icons.receipt_long,color:forest),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(str(p['plan_name']),style:const TextStyle(fontWeight:FontWeight.w800)),Text(str(p['created_at']),style:const TextStyle(color:muted,fontSize:12))])),Column(crossAxisAlignment:CrossAxisAlignment.end,children:[Text('${str(p['amount'])} ₺',style:const TextStyle(fontWeight:FontWeight.w800)),SoftBadge(str(p['status'])=='approved'?'Onaylandı':str(p['status'])=='pending'?'Beklemede':'İptal')])])))]);
  }));
}
class MembershipScreen extends StatefulWidget{
  final AcademyStore store;const MembershipScreen({super.key,required this.store});
  @override State<MembershipScreen> createState()=>_MembershipState();
}
class _MembershipState extends State<MembershipScreen>{late Future<List<dynamic>> future;
  @override void initState(){super.initState();future=widget.store.api.plans();}
  @override Widget build(BuildContext context)=>AppPage(title:'Üyelik ve paketler',child:FutureBuilder<List<dynamic>>(future:future,builder:(ctx,s){
    if(s.hasError)return StateMessage(s.error.toString());if(!s.hasData)return const Center(child:CircularProgressIndicator());
    final plans=s.data!.whereType<Map>().toList();
    final active=widget.store.active;
    return ListView(padding:const EdgeInsets.all(20),children:[const Eyebrow('Dijital akademi'),const SizedBox(height:10),
      Text(active?'Aboneliğin aktif.':'Tüm eğitimler tek yerde.',style:Theme.of(context).textTheme.headlineLarge),const SizedBox(height:10),
      Text(active?'İçeriklerine abonelik süren boyunca erişebilirsin.':'Aboneliğin etkinleştirildiğinde tüm eğitimlere erişirsin.',style:const TextStyle(color:muted)),
      const SizedBox(height:20),for(final p in plans)Card(child:Padding(padding:const EdgeInsets.symmetric(horizontal:18,vertical:18),child:Row(children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(str(p['name']),style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800)),const SizedBox(height:4),Text('${asInt(p['days'])} gün erişim',style:const TextStyle(color:muted,fontSize:12))])),
        Text('${asDouble(p['price']).toStringAsFixed(0)} TL',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:19,color:forest)),
      ]))),
      const SizedBox(height:10),if(AppConfig.storeReaderMode)Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:soft,borderRadius:BorderRadius.circular(16)),
        child:const Text('Bu mobil uygulama mevcut üyelerin dersleri izlemesi için tasarlanmıştır. Dijital abonelik ödemesi uygulama içinde alınmaz. Mevcut web hesabınla giriş yaptığında aktif aboneliğin otomatik tanınır.',style:TextStyle(color:forest,height:1.6,fontSize:12)))
    ]);
  }));
}

class DeleteAccountScreen extends StatefulWidget {
  final AcademyStore store;const DeleteAccountScreen({super.key,required this.store});
  @override State<DeleteAccountScreen> createState()=>_DeleteAccountState();
}
class _DeleteAccountState extends State<DeleteAccountScreen> {
  final password=TextEditingController();bool confirmed=false,busy=false;
  @override void dispose(){password.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>AppPage(title:'Hesabımı sil',child:ListView(padding:const EdgeInsets.all(24),children:[
    const Icon(Icons.warning_amber_rounded,size:52,color:Color(0xFFBA3D27)),const SizedBox(height:17),
    Text('Hesabını kalıcı olarak sil',style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:12),
    const Text('Bu işlem giriş bilgilerini, ders ilerlemeni ve verdiğin puanları kaldırır. Geri alınamaz. Yasal saklama gerekliliğine tabi ödeme kayıtları kişisel bilgilerin silinerek tutulabilir.',style:TextStyle(color:muted,height:1.6)),
    const SizedBox(height:24),TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Şifreni doğrula')),
    const SizedBox(height:10),CheckboxListTile(contentPadding:EdgeInsets.zero,value:confirmed,controlAffinity:ListTileControlAffinity.leading,title:const Text('Hesabımın silineceğini ve işlemin geri alınamayacağını anlıyorum.',style:TextStyle(fontSize:12)),onChanged:(v)=>setState(()=>confirmed=v??false)),
    const SizedBox(height:18),FilledButton(style:FilledButton.styleFrom(backgroundColor:const Color(0xFFB43E2D)),onPressed:!confirmed||busy?null:()async{
      setState(()=>busy=true);
      try{await widget.store.api.deleteAccount(password.text);await widget.store.reload();if(context.mounted){Navigator.of(context).popUntil((r)=>r.isFirst);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Hesabın silindi.')));}}
      catch(e){if(context.mounted)showFailure(context,e);}finally{if(mounted)setState(()=>busy=false);}
    },child:Text(busy?'İşleniyor...':'Hesabımı kalıcı olarak sil'))
  ]));
}
