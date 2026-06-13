import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/garden/data/garden_repository.dart';
import 'features/garden/data/mock_garden_repository.dart';
import 'features/garden/logic/garden_provider.dart';
import 'features/garden/presentation/garden_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
        home: const GardenScreen(),
      ),
    );
  }
}
