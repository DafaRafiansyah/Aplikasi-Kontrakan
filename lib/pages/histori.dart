import 'package:flutter/material.dart';
import 'package:aplikasi_kontrakan/database_helper.dart';

class Histori extends StatelessWidget {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Histori({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histori Penghuni Kamar'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbHelper.queryTenantHistory(1),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final histories = snapshot.data;
            return ListView.builder(
              itemCount: histories?.length ?? 0,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Nama: ${histories![index]['id_penghuni']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kamar: ${histories[index]['id_kamar']}'),
                      Text('Tanggal Masuk: ${histories[index]['tanggal_masuk']}'),
                      Text('Tanggal Keluar: ${histories[index]['tanggal_keluar'] ?? "Masih Menghuni"}'),
                      Text('Detail Pembayaran: ${histories[index]['detail_pembayaran']}'),
                      Text('Catatan: ${histories[index]['catatan']}'),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
