import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/data/auth_api.dart';
import '../features/auth/data/token_store.dart';
import '../features/auth/presentation/auth_view_model.dart';
import '../features/chat/presentation/chat_view_model.dart';
import 'router/app_router.dart';

class CobipApp extends StatefulWidget {
  const CobipApp({super.key, this.auth, this.router});
  final AuthViewModel? auth;
  final GoRouter? router;

  @override
  State<CobipApp> createState() => _CobipAppState();
}

class _CobipAppState extends State<CobipApp> {
  late final AuthViewModel _auth;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth =
        widget.auth ??
        AuthViewModel(
          api: AuthApi.fromEnvironment(),
          tokenStore: SecureTokenStore(),
        );
    _router = widget.router ?? appRouter;
    _auth.addListener(_router.refresh);
    _auth.restore();
  }

  @override
  void dispose() {
    _auth.removeListener(_router.refresh);
    if (widget.auth == null) _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
      ],
      child: MaterialApp.router(
        title: 'COBIA',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5538F2)),
          scaffoldBackgroundColor: const Color(0xFFF9F8FF),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}
