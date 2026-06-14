import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/auth_session.dart';
import 'features/auth/data/token_store.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/garden/data/garden_repository.dart';
import 'features/garden/data/mock_garden_repository.dart';
import 'features/garden/logic/garden_provider.dart';
import 'features/shared/config/app_config.dart';
import 'features/shared/network/api_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Auth layer ──────────────────────────────────────────────────────
        // AuthSession is a ChangeNotifier — AuthGate watches it to switch
        // between the login screen and the garden.
        ChangeNotifierProvider<AuthSession>(
          create: (_) => AuthSession(),
        ),

        // ApiClient constructed with the platform-aware base URL; the
        // onUnauthorized hook is wired by AuthGate after the tree is built.
        Provider<ApiClient>(
          create: (_) => ApiClient(baseUrl: AppConfig.apiBaseUrl),
        ),

        // TokenStore wraps flutter_secure_storage for JWT persistence.
        Provider<TokenStore>(
          create: (_) => TokenStore(),
        ),

        // AuthRepository uses ApiClient, TokenStore, and AuthSession to
        // perform login/register/restore/logout and keep them in sync.
        Provider<AuthRepository>(
          create: (ctx) => AuthRepository(
            client: ctx.read<ApiClient>(),
            store: ctx.read<TokenStore>(),
            session: ctx.read<AuthSession>(),
          ),
        ),

        // ── Garden layer (Phase 10 will swap MockGardenRepository) ─────────
        Provider<GardenRepository>(
          create: (_) => MockGardenRepository(),
        ),
        ChangeNotifierProxyProvider<GardenRepository, GardenProvider>(
          create: (ctx) =>
              GardenProvider(repository: ctx.read<GardenRepository>()),
          update: (_, repo, prev) =>
              prev ?? GardenProvider(repository: repo),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Application Nhat Ky',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: const Color(0xFF6B8E5A)),
          useMaterial3: true,
        ),
        // AuthGate handles splash → login/register → garden routing.
        home: const AuthGate(),
      ),
    );
  }
}
