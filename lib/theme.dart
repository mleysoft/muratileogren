import 'package:flutter/material.dart';

const ink=Color(0xFF14251D);
const forest=Color(0xFF1E4635);
const lime=Color(0xFFC8F34B);
const paper=Color(0xFFF7F9F5);
const muted=Color(0xFF6C7D74);
const soft=Color(0xFFE9EFEB);

ThemeData academyTheme(){
  final base=ThemeData(useMaterial3:true,brightness:Brightness.light);
  return base.copyWith(
    scaffoldBackgroundColor:paper,
    colorScheme:ColorScheme.fromSeed(seedColor:forest,primary:forest,onPrimary:Colors.white,secondary:lime,surface:Colors.white,brightness:Brightness.light),
    textTheme:base.textTheme.apply(fontFamily:'Roboto',bodyColor:ink,displayColor:ink).copyWith(
      displayLarge:const TextStyle(fontSize:40,fontWeight:FontWeight.w800,height:1.04,letterSpacing:-1.7,color:ink),
      headlineLarge:const TextStyle(fontSize:30,fontWeight:FontWeight.w800,letterSpacing:-.8,color:ink),
      headlineMedium:const TextStyle(fontSize:25,fontWeight:FontWeight.w800,letterSpacing:-.5,color:ink),
      titleLarge:const TextStyle(fontSize:19,fontWeight:FontWeight.w700,color:ink),
      titleMedium:const TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:ink),
      bodyMedium:const TextStyle(fontSize:14,height:1.5,color:ink),
    ),
    appBarTheme:const AppBarTheme(backgroundColor:paper,foregroundColor:ink,scrolledUnderElevation:0,elevation:0,centerTitle:false),
    dividerColor:soft,
    cardTheme:CardThemeData(color:Colors.white,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22),side:const BorderSide(color:soft))),
    inputDecorationTheme:InputDecorationTheme(
      filled:true,fillColor:Colors.white,contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:16),
      hintStyle:const TextStyle(color:muted),
      border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:soft)),
      enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:soft)),
      focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:forest,width:1.5)),
    ),
    filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(backgroundColor:ink,foregroundColor:Colors.white,
      minimumSize:const Size(0,52),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),
      textStyle:const TextStyle(fontWeight:FontWeight.w800,fontSize:15))),
    outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(foregroundColor:ink,
      minimumSize:const Size(0,52),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),
      side:const BorderSide(color:soft),textStyle:const TextStyle(fontWeight:FontWeight.w700))),
    chipTheme:base.chipTheme.copyWith(backgroundColor:Colors.white,side:const BorderSide(color:soft),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),labelStyle:const TextStyle(color:ink,fontWeight:FontWeight.w600)),
  );
}
