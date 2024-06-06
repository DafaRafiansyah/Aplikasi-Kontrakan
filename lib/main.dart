import 'package:aplikasi_kontrakan/pages/navigation_menu.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.white,
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.black),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blueGrey),
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.blueGrey,
          selectionColor: Colors.blueGrey.withOpacity(0.5),
          selectionHandleColor: Colors.blueGrey,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blueGrey,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.blueGrey,
        ),
      ),
      title: 'Aplikasi Kontrakan',
      debugShowCheckedModeBanner: false,
      home: const NavMenu(),
    );
  }
}
