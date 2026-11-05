import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/sync_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SyncController()),
      ],
      child: const LedMatrixApp(),
    ),
  );
}

class LedMatrixApp extends StatelessWidget {
  const LedMatrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đồng Bộ LED Ma Trận HD-WF2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const HomeScreen(),
    );
  }
}
