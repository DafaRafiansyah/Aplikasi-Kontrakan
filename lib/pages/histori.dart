import 'package:flutter/material.dart';
import 'package:aplikasi_kontrakan/database_helper.dart';

class Histori extends StatefulWidget {
  const Histori({super.key});

  @override
  HistoriState createState() => HistoriState();
}

class HistoriState extends State<Histori> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  String _sortBy = 'nomor_kamar';
  bool _ascending = true;

  Future<void> _loadTenants() async {
    setState(() {});
  }

  void _sortHistories(String sortBy, bool ascending) {
    setState(() {
      _sortBy = sortBy;
      _ascending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histori Penghuni Kamar',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (value) {
              if (value.startsWith('nomor_kamar')) {
                _sortHistories('nomor_kamar', value.endsWith('asc'));
              } else if (value.startsWith('tanggal_masuk')) {
                _sortHistories('tanggal_masuk', value.endsWith('asc'));
              }
            },
            itemBuilder: (BuildContext context) => [
              CheckedPopupMenuItem(
                value: 'nomor_kamar_asc',
                checked: _sortBy == 'nomor_kamar' && _ascending,
                child: const Text('Nomor Kamar Ascending'),
              ),
              CheckedPopupMenuItem(
                value: 'nomor_kamar_desc',
                checked: _sortBy == 'nomor_kamar' && !_ascending,
                child: const Text('Nomor Kamar Descending'),
              ),
              CheckedPopupMenuItem(
                value: 'tanggal_masuk_asc',
                checked: _sortBy == 'tanggal_masuk' && _ascending,
                child: const Text('Tanggal Masuk Ascending'),
              ),
              CheckedPopupMenuItem(
                value: 'tanggal_masuk_desc',
                checked: _sortBy == 'tanggal_masuk' && !_ascending,
                child: const Text('Tanggal Masuk Descending'),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbHelper.queryHistoriPenghuni(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            var histories =
                List<Map<String, dynamic>>.from(snapshot.data ?? []);
            histories.sort((a, b) {
              int compare;
              if (_sortBy == 'nomor_kamar') {
                compare = a['nomor_kamar'].compareTo(b['nomor_kamar']);
              } else {
                compare = a['tanggal_masuk'].compareTo(b['tanggal_masuk']);
              }
              return _ascending ? compare : -compare;
            });

            return ListView.builder(
              itemCount: histories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Card(
                    color: histories[index]['status_pembayaran'] == 'Lunas'
                        ? Colors.blueGrey[100]
                        : Colors.amber[200],
                    elevation: 5,
                    child: ListTile(
                      title: Text(
                          '${histories[index]['nomor_kamar']} - ${histories[index]['nama']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${histories[index]['tanggal_masuk']} - ${histories[index]['tanggal_keluar']}'),
                          Text('Nomor Telepon: ${histories[index]['no_telp']}'),
                          Text(
                              'Total Pembayaran: ${dbHelper.formatCurrency(histories[index]['total_pembayaran'])}'),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TenantDetailsScreen(
                              tenant: histories[index],
                              dbHelper: dbHelper,
                              reloadTenants: _loadTenants,
                            ),
                          ),
                        );
                      },
                    ),
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

class TenantDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> tenant;
  final DatabaseHelper dbHelper;
  final Function reloadTenants;

  const TenantDetailsScreen({
    super.key,
    required this.tenant,
    required this.dbHelper,
    required this.reloadTenants,
  });

  @override
  TenantDetailsScreenState createState() => TenantDetailsScreenState();
}

class TenantDetailsScreenState extends State<TenantDetailsScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  late String _statusPembayaran;

  @override
  void initState() {
    super.initState();
    _statusPembayaran = widget.tenant['status_pembayaran'];
    _updateTotalPaymentAndStatus();
  }

  Future<List<Map<String, dynamic>>> _getPayments(int tenantId) async {
    return await dbHelper.queryPembayaranPenghuni(tenantId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text(
          'Riwayat Penghuni',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: _buildTenantDetails(),
    );
  }

  Future<void> _updateTotalPaymentAndStatus() async {
    final payments = await _getPayments(widget.tenant['id']);
    _statusPembayaran =
        payments.any((payment) => payment['status_pembayaran'] == 'Belum Lunas')
            ? 'Belum Lunas'
            : 'Lunas';

    await widget.dbHelper
        .updateStatusPembayaran(widget.tenant['id'], _statusPembayaran);
    widget.reloadTenants();
    setState(() {});
  }

  Future<void> _showEditPaymentDialog(Map<String, dynamic> payment) async {
    final formKey = GlobalKey<FormState>();
    final TextEditingController statusPembayaranController =
        TextEditingController(text: payment['status_pembayaran']);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Pembayaran'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: statusPembayaranController.text,
                    decoration:
                        const InputDecoration(labelText: 'Status Pembayaran'),
                    onChanged: (String? newValue) {
                      setState(() {
                        statusPembayaranController.text = newValue!;
                      });
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'Belum Lunas',
                        child: Text('Belum Lunas'),
                      ),
                      DropdownMenuItem(
                        value: 'Lunas',
                        child: Text('Lunas'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Pilih status pembayaran';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, {
                    'status_pembayaran': statusPembayaranController.text,
                  });
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      await widget.dbHelper.updatePembayaranPenghuni({
        'id': payment['id'],
        'status_pembayaran': result['status_pembayaran'],
      });
      _updateTotalPaymentAndStatus();
      setState(() {});
    }
  }

  Widget _buildTenantDetails() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama: ${widget.tenant['nama']}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Email: ${widget.tenant['email']}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Nomor Telepon: ${widget.tenant['no_telp']}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Tanggal Masuk: ${widget.tenant['tanggal_masuk']}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Tanggal Keluar: ${widget.tenant['tanggal_keluar']}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
                'Total Pembayaran: ${dbHelper.formatCurrency(widget.tenant['total_pembayaran'])}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Nomor Kamar: ${widget.tenant['nomor_kamar']}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Status Pembayaran: $_statusPembayaran',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            const Text('Histori Pembayaran',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getPayments(widget.tenant['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text('Error loading payments');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Belum ada pembayaran');
                } else {
                  List<Map<String, dynamic>> payments = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...payments.map((payment) {
                        return Card(
                          color: payment['status_pembayaran'] == 'Lunas'
                              ? Colors.blueGrey[100]
                              : Colors.amber[200],
                          elevation: 5,
                          child: ListTile(
                            title: Text(
                                '${payment['tanggal_masuk']} - ${payment['tanggal_habis']}'),
                            subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Tagihan: ${dbHelper.formatCurrency(payment['tagihan'].toString())}'),
                                  Text(
                                      'Status Pembayaran: ${payment['status_pembayaran']}'),
                                ]),
                            onTap: () => _showEditPaymentDialog(payment),
                          ),
                        );
                      }),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
