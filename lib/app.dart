import 'package:flutter/material.dart';
import 'screens/home_page.dart'; // 이 라인만 추가하면 됨

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raou',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Raou'),
    );
  }
}
