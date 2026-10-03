import 'package:provider/provider.dart';

import '../features/chat/presentation/chat_view_model.dart';

import 'package:flutter/material.dart';

import 'router/app_router.dart';

class CobipApp extends StatelessWidget {
  const CobipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(),
      child: MaterialApp.router(
        title: 'COBIA',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5538F2)),
          scaffoldBackgroundColor: const Color(0xFFF9F8FF),
          useMaterial3: true,
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
