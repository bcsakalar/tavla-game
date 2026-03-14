import 'package:flutter/material.dart';
import '../core/theme/tavla_theme.dart';
import 'routes.dart';

class TavlaApp extends StatelessWidget {
  const TavlaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tavla Online',
      debugShowCheckedModeBanner: false,
      theme: TavlaTheme.theme,
      darkTheme: TavlaTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
