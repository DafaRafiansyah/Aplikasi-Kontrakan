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
        title: const Text(
          'Daftar Kamar',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
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
      title: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      children: rooms.map((room) {
        final isInteractive =
            room['status'] == 'kosong' || room['status'] == 'dalam_perawatan';
        final text = isInteractive
            ? room['status'] == 'kosong'
                ? 'Status: Kosong'
                : 'Status: Dalam Perawatan'
            : 'Ditempati oleh: ${room['status']}';
        final cardColor =
            isInteractive ? Colors.blueGrey[100] : Colors.amber[200];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Card(
            color: cardColor,
            elevation: 5,
            child: ListTile(
              title: Text(
                'Kamar ${room['nomor_kamar']}',
                style: const TextStyle(color: Colors.black),
              ),
              subtitle: Text(
                text,
                style: const TextStyle(color: Colors.black),
              ),
              onTap: isInteractive
                  ? () => _showRoomOptions(room['id'], room['status'])
                  : null,
              enabled: isInteractive,
            ),
          ),
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.blueGrey,
                ),
                child: ListTile(
                  title: const Text(
                    'Dalam Perawatan',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    _updateRoomStatus(roomId, 'dalam_perawatan');
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.blueGrey,
                ),
                child: ListTile(
                  title: const Text(
                    'Kosong',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    _updateRoomStatus(roomId, 'kosong');
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          actions: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Batal'),
              ),
            ),
          ],
        );
      },
    );
  }
}
