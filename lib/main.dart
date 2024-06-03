import 'package:aplikasi_kontrakan/pages/navigation_menu.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Aplikasi Kontrakan',
      debugShowCheckedModeBanner: false,
      home: NavMenu(),
    );
  }
}
