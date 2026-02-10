import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/api_service.dart';
import 'features/chat/data/chat_repository.dart';
import 'features/chat/logic/chat_provider.dart';
import 'features/journal/data/journal_repository.dart';
import 'features/journal/logic/journal_provider.dart';
import 'features/garden/data/garden_repository.dart';
import 'features/garden/logic/garden_provider.dart';
import 'features/splash/splash_screen.dart';
import 'main_shell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // API Service
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        // Chat Repository
        ProxyProvider<ApiService, ChatRepository>(
          update: (_, apiService, __) => ChatRepository(apiService: apiService),
        ),
        // Chat Provider
        ChangeNotifierProxyProvider<ChatRepository, ChatProvider>(
          create: (context) => ChatProvider(
            repository: Provider.of<ChatRepository>(context, listen: false)
          ),
          update: (_, repository, previous) => 
            previous ?? ChatProvider(repository: repository),
        ),
        // Journal Repository
        Provider<JournalRepository>(
          create: (_) => JournalRepository(),
        ),
        // Journal Provider
        ChangeNotifierProxyProvider<JournalRepository, JournalProvider>(
          create: (context) => JournalProvider(
            repository: Provider.of<JournalRepository>(context, listen: false)
          ),
          update: (_, repository, previous) =>
            previous ?? JournalProvider(repository: repository),
        ),
        // Garden Repository
        Provider<GardenRepository>(
          create: (_) => GardenRepository(),
        ),
        // Garden Provider
        ChangeNotifierProxyProvider<GardenRepository, GardenProvider>(
          create: (context) => GardenProvider(
            repository: Provider.of<GardenRepository>(context, listen: false)
          ),
          update: (_, repository, previous) =>
            previous ?? GardenProvider(repository: repository),
        ),
      ],
      child: MaterialApp(
        title: 'Shellmind',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D8B8B)),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFAF8F0),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFAF8F0),
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        home: const SplashScreen(nextScreen: MainShell()),
      ),
    );
  }
}
