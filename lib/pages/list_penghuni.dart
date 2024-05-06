import 'package:flutter/material.dart';

class ListPenghuni extends StatelessWidget {
  const ListPenghuni({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'List Penghuni',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
