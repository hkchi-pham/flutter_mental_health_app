import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/auth_session.dart';
import 'features/auth/data/token_store.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/garden/data/api_garden_repository.dart';
import 'features/garden/data/cache/change_queue.dart';
import 'features/garden/data/cache/garden_cache_store.dart';
import 'features/garden/data/garden_repository.dart';
import 'features/garden/data/remote/garden_badge_remote_data_source.dart';
import 'features/garden/data/remote/garden_decoration_remote_data_source.dart';
import 'features/garden/data/remote/garden_item_remote_data_source.dart';
import 'features/garden/data/remote/garden_user_remote_data_source.dart';
import 'features/garden/data/sync/sync_coordinator.dart';
import 'features/garden/logic/garden_provider.dart';
import 'features/journal/data/cache/journal_cache_store.dart';
import 'features/journal/data/cache/journal_change_queue.dart';
import 'features/journal/data/journal_repository.dart';
import 'features/journal/data/remote/journal_remote_data_source.dart';
import 'features/journal/logic/journal_provider.dart';
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

        // ── Garden layer (Phase 10 swap: MockGardenRepository -> ApiGardenRepository) ──
        //
        // ApiGardenRepository is built once here and exposed as BOTH the
        // concrete type (for SyncCoordinator) and the abstract GardenRepository
        // interface (for GardenProvider). A single instance is shared.
        Provider<ApiGardenRepository>(
          create: (ctx) => ApiGardenRepository(
            items: GardenItemRemoteDataSource(ctx.read<ApiClient>()),
            decos: GardenDecorationRemoteDataSource(ctx.read<ApiClient>()),
            badges: GardenBadgeRemoteDataSource(ctx.read<ApiClient>()),
            user: GardenUserRemoteDataSource(ctx.read<ApiClient>()),
            session: ctx.read<AuthSession>(),
            cache: GardenCacheStore(),
            queue: ChangeQueue(),
          ),
        ),

        // Expose the same instance through the GardenRepository interface so
        // GardenProvider and any future consumers remain decoupled from the
        // concrete type.
        ProxyProvider<ApiGardenRepository, GardenRepository>(
          update: (_, repo, prev) => repo,
        ),

        // ── Journal layer (Phase 11) ────────────────────────────────────────
        //
        // Offline-first journal data layer mirroring the garden template:
        // JournalRepository (cache-first read, optimistic writes, offline queue)
        // sits behind a JournalProvider ChangeNotifier the journal screens watch.
        // Reads ApiClient + AuthSession already provided above. Declared BEFORE
        // SyncCoordinator so the coordinator can drive the journal reconnect sync.
        Provider<JournalRepository>(
          create: (ctx) => JournalRepository(
            remote: JournalRemoteDataSource(ctx.read<ApiClient>()),
            cache: JournalCacheStore(),
            queue: JournalChangeQueue(),
            session: ctx.read<AuthSession>(),
          ),
        ),

        ChangeNotifierProxyProvider<JournalRepository, JournalProvider>(
          create: (ctx) =>
              JournalProvider(repository: ctx.read<JournalRepository>()),
          update: (_, repo, prev) =>
              prev ?? JournalProvider(repository: repo),
        ),

        // SyncCoordinator — event-driven triggers only (app-open / reconnect /
        // resume-from-background). Created once; start() is called here so
        // the app-open sync fires on the first post-frame callback. Drives BOTH
        // the garden sync and the journal offline write-queue replay/refresh.
        Provider<SyncCoordinator>(
          create: (ctx) {
            final coordinator = SyncCoordinator(
              repo: ctx.read<ApiGardenRepository>(),
              session: ctx.read<AuthSession>(),
              extraSyncs: [
                () => ctx.read<JournalProvider>().syncOnReconnect(),
              ],
            );
            coordinator.start();
            return coordinator;
          },
          dispose: (_, coordinator) => coordinator.dispose(),
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
        // NO app-wide width cap. Responsiveness is per-screen:
        //   • Full-bleed screens (garden, splash, auth backgrounds) render
        //     edge-to-edge and scale via BoxFit.cover / percentage layout.
        //   • Width-limited screens (chat, journal, shop, settings) opt in by
        //     wrapping their body in `MaxWidthBox` (see core/responsive.dart).
        // A global ConstrainedBox here would letterbox the garden, which must
        // fill 100% of the window width.
        // AuthGate handles splash → login/register → garden routing.
        home: const AuthGate(),
      ),
    );
  }
}
