import 'package:flutter/material.dart';

class Histori extends StatelessWidget {
  const Histori({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'Histori',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
