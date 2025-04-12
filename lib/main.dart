import 'package:flutter/material.dart';
import 'package:hacktrack/HomeScreen.dart';
import 'package:hacktrack/routes.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      onGenerateRoute: Routes.generateRoute,
      home: HomeScreen(),
    );
  }
}
