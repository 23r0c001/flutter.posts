import 'package:flutter/material.dart';
import 'src/routing/app_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  // 1. Ensure Flutter is ready (required for C#-style async setup)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize your Local SQLite DB here later
  // await LocalDb.init();

  // 3. Show URLs in browser (largely for dev/debug)
  usePathUrlStrategy();

  // 4. Party
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instead of 'home:', we use '.router' for Web/Deep-linking support
    return MaterialApp.router(
      title: 'My Forum App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),

      // routerConfig: myAppRouter, // We will define this in a separate file
      routerConfig: appRouter,
    );
  }
}
