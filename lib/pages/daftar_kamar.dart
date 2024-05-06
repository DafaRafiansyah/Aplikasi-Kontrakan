import 'package:flutter/material.dart';

class DaftarKamar extends StatelessWidget {
  const DaftarKamar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'Daftar Kamar',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
