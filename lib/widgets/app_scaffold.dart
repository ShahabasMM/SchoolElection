import 'package:flutter/material.dart';
import 'bottom_nav.dart';
import 'page_header.dart';
class ElectionScaffold extends StatelessWidget{final Widget body;final int navIndex;final bool showBack,darkHeader;final VoidCallback? onFullscreen;final Color? backgroundColor;final Widget? floatingActionButton;const ElectionScaffold({super.key,required this.body,required this.navIndex,this.showBack=true,this.darkHeader=false,this.onFullscreen,this.backgroundColor,this.floatingActionButton});@override Widget build(BuildContext context)=>Scaffold(backgroundColor:backgroundColor,appBar:ElectionPageHeader(showBack:showBack,dark:darkHeader,onFullscreen:onFullscreen),body:body,bottomNavigationBar:PageBottomNav(selectedIndex:navIndex),floatingActionButton:floatingActionButton);}
