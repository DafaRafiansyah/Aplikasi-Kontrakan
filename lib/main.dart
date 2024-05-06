import 'package:aplikasi_kontrakan/pages/navigation_menu.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Aplikasi Kontrakan',
      debugShowCheckedModeBanner: false,
      home: NavMenu(),
    );
  }
}
