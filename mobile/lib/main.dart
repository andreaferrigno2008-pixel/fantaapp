import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';

void main() {
  runApp(const ProviderScope(child: FantaApp()));
}

class FantaApp extends StatelessWidget {
  const FantaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fanta-App',
      theme: fantaAppTheme,
      darkTheme: fantaAppDarkTheme,
      routerConfig: appRouter,
    );
  }
}
