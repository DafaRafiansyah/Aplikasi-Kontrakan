import 'package:flutter/material.dart';
import 'package:aplikasi_kontrakan/database_helper.dart';

class DaftarKamar extends StatefulWidget {
  const DaftarKamar({super.key});

  @override
  DaftarKamarState createState() => DaftarKamarState();
}

class DaftarKamarState extends State<DaftarKamar> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<void> _updateRoomStatus(int roomId, String status) async {
    await dbHelper.updateRoomStatus(roomId, status);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Kamar'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbHelper.queryAllRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final rooms = snapshot.data ?? [];
            final lantai1 = rooms.where((room) => room['lantai'] == 1).toList();
            final lantai2 = rooms.where((room) => room['lantai'] == 2).toList();

            return ListView(
              children: [
                _buildLantaiSection('Lantai 1', lantai1),
                _buildLantaiSection('Lantai 2', lantai2),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildLantaiSection(String title, List<Map<String, dynamic>> rooms) {
    return ExpansionTile(
      title: Text(title),
      children: rooms.map((room) {
        final isInteractive = room['status'] == 'kosong' || room['status'] == 'dalam_perawatan';
        return ListTile(
          title: Text('Kamar ${room['nomor_kamar']}'),
          subtitle: Text('Status: ${room['status']}'),
          onTap: isInteractive ? () => _showRoomOptions(room['id'], room['status']) : null,
          enabled: isInteractive,
        );
      }).toList(),
    );
  }

  void _showRoomOptions(int roomId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Status Kamar'),
          content: Text('Status saat ini: $currentStatus'),
          actions: [
            TextButton(
              onPressed: () {
                _updateRoomStatus(roomId, 'dalam_perawatan');
                Navigator.pop(context);
              },
              child: const Text('Dalam Perawatan'),
            ),
            TextButton(
              onPressed: () {
                _updateRoomStatus(roomId, 'kosong');
                Navigator.pop(context);
              },
              child: const Text('Kosong'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }
}
