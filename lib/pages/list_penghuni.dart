import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aplikasi_kontrakan/database_helper.dart';
import 'package:aplikasi_kontrakan/tambah_penghuni.dart';
import 'package:intl/intl.dart';

class ListPenghuni extends StatefulWidget {
  const ListPenghuni({super.key});

  @override
  ListPenghuniState createState() => ListPenghuniState();
}

class ListPenghuniState extends State<ListPenghuni> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  String _sortBy = 'nomor_kamar';
  bool _ascending = true;

  Future<void> _loadTenants() async {
    setState(() {});
  }

  void _sortTenants(String sortBy, bool ascending) {
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
          'List Penghuni',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            onPressed: () {
              _showAddTenantForm(context);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (value) {
              if (value.startsWith('nomor_kamar')) {
                _sortTenants('nomor_kamar', value.endsWith('asc'));
              } else if (value.startsWith('tanggal_masuk')) {
                _sortTenants('tanggal_masuk', value.endsWith('asc'));
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
        future: dbHelper.querySemuaPenghuniDenganKamar(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            var tenants = List<Map<String, dynamic>>.from(snapshot.data ?? []);
            tenants.sort((a, b) {
              int compare;
              if (_sortBy == 'nomor_kamar') {
                compare = a['nomor_kamar'].compareTo(b['nomor_kamar']);
              } else {
                compare = a['tanggal_masuk'].compareTo(b['tanggal_masuk']);
              }
              return _ascending ? compare : -compare;
            });

            return ListView.builder(
              itemCount: tenants.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Dismissible(
                    key: Key(tenants[index]['id'].toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Konfirmasi Hapus'),
                            content: const Text(
                                'Anda yakin ingin menghapus penghuni ini?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.of(context).pop(true);
                                  await dbHelper.movePenghuniKeHistoriPenghuni(
                                      tenants[index]['id']);
                                  _loadTenants();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) async {
                      await dbHelper
                          .movePenghuniKeHistoriPenghuni(tenants[index]['id']);
                      _loadTenants();
                    },
                    child: Card(
                      color: tenants[index]['status_pembayaran'] == 'Lunas'
                          ? Colors.blueGrey[100]
                          : Colors.amber[200],
                      elevation: 5,
                      child: ListTile(
                        title: Text(
                            '${tenants[index]['nomor_kamar']} - ${tenants[index]['nama']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (tenants[index]['tanggal_masuk'] != '-' ||
                                tenants[index]['tanggal_habis'] != '-')
                              Text(
                                  '${tenants[index]['tanggal_masuk']} - ${tenants[index]['tanggal_habis']}'),
                            Text('Nomor Telepon: ${tenants[index]['no_telp']}'),
                            Text(
                                'Total Pembayaran: ${dbHelper.formatCurrency(tenants[index]['total_pembayaran'])}'),
                          ],
                        ),
                        onTap: () {
                          _showEditTenantForm(context, tenants[index]);
                        },
                      ),
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

  Future<void> _showAddTenantForm(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddTenantForm(dbHelper: dbHelper)),
    );
    if (result == true) {
      _loadTenants();
    }
  }

  Future<void> _showEditTenantForm(
      BuildContext context, Map<String, dynamic> tenant) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditTenantForm(
                dbHelper: dbHelper,
                tenant: tenant,
                reloadTenants: _loadTenants,
              )),
    );
    if (result == true) {
      _loadTenants();
    }
  }
}

class EditTenantForm extends StatefulWidget {
  final DatabaseHelper dbHelper;
  final Map<String, dynamic> tenant;
  final Function reloadTenants;

  const EditTenantForm({
    super.key,
    required this.dbHelper,
    required this.tenant,
    required this.reloadTenants,
  });

  @override
  EditTenantFormState createState() => EditTenantFormState();
}

class EditTenantFormState extends State<EditTenantForm> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper dbHelper = DatabaseHelper();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noTelpController = TextEditingController();
  String? _selectedRoom;
  List<Map<String, dynamic>> _availableRooms = [];
  bool _isEditMode = false;
  int _totalPayment = 0;
  String _statusPembayaran = 'Belum Lunas';
  String _tanggalMasuk = '-';
  String _tanggalHabis = '-';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadAvailableRooms();
    _updateTotalPaymentAndStatus();
  }

  void _initializeControllers() {
    _nameController.text = widget.tenant['nama'];
    _emailController.text = widget.tenant['email'];
    _noTelpController.text = widget.tenant['no_telp'];
    _selectedRoom = widget.tenant['nomor_kamar'].toString();
  }

  Future<void> _loadAvailableRooms() async {
    final rooms = await widget.dbHelper.queryAllRooms();
    setState(() {
      _availableRooms = rooms
          .where((room) =>
              room['status'] == 'kosong' ||
              room['id'] == int.parse(_selectedRoom!))
          .toList();
      _availableRooms
          .sort((a, b) => a['nomor_kamar'].compareTo(b['nomor_kamar']));
    });
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueGrey,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      String formattedDate = DateFormat('dd-MM-yyyy').format(picked);
      setState(() {
        controller.text = formattedDate;
      });
    }
  }

  Future<void> _showEditPaymentDialog(Map<String, dynamic> payment) async {
    final formKey = GlobalKey<FormState>();
    final TextEditingController tanggalMasukController =
        TextEditingController(text: payment['tanggal_masuk']);
    final TextEditingController tanggalHabisController =
        TextEditingController(text: payment['tanggal_habis']);
    final TextEditingController tagihanController =
        TextEditingController(text: payment['tagihan']);
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: tanggalMasukController,
                          decoration:
                              const InputDecoration(labelText: 'Tanggal Masuk'),
                          readOnly: true,
                          onTap: () =>
                              _selectDate(context, tanggalMasukController),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Pilih tanggal masuk';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: tanggalHabisController,
                          decoration:
                              const InputDecoration(labelText: 'Tanggal Habis'),
                          readOnly: true,
                          onTap: () =>
                              _selectDate(context, tanggalHabisController),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Pilih tanggal habis';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: tagihanController,
                    decoration: const InputDecoration(labelText: 'Tagihan'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Tagihan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
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
                    'tanggal_masuk': tanggalMasukController.text,
                    'tanggal_habis': tanggalHabisController.text,
                    'tagihan': tagihanController.text,
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
        'tanggal_masuk': result['tanggal_masuk'],
        'tanggal_habis': result['tanggal_habis'],
        'tagihan': result['tagihan'],
        'status_pembayaran': result['status_pembayaran'],
      });
      _updateTotalPaymentAndStatus();
      setState(() {});
    }
  }

  Future<void> _showAddPaymentDialog() async {
    final formKey = GlobalKey<FormState>();

    final TextEditingController tanggalMasukController =
        TextEditingController();
    final TextEditingController tanggalHabisController =
        TextEditingController();
    final TextEditingController tagihanController = TextEditingController();
    final TextEditingController statusPembayaranController =
        TextEditingController();

    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Pembayaran'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: tanggalMasukController,
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Masuk',
                          ),
                          readOnly: true,
                          onTap: () =>
                              _selectDate(context, tanggalMasukController),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Pilih tanggal masuk';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: tanggalHabisController,
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Habis',
                          ),
                          readOnly: true,
                          onTap: () =>
                              _selectDate(context, tanggalHabisController),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Pilih tanggal habis';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: tagihanController,
                    decoration: const InputDecoration(labelText: 'Tagihan'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Tagihan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: null,
                    decoration: const InputDecoration(
                      labelText: 'Status Pembayaran',
                    ),
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
                    onChanged: (String? newValue) {
                      setState(() {
                        statusPembayaranController.text = newValue!;
                      });
                    },
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
                  await widget.dbHelper.insertPembayaranPenghuni({
                    'id_penghuni': widget.tenant['id'],
                    'tanggal_masuk': tanggalMasukController.text,
                    'tanggal_habis': tanggalHabisController.text,
                    'tagihan': tagihanController.text,
                    'status_pembayaran': statusPembayaranController.text,
                  });
                  _updateTotalPaymentAndStatus();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateTotalPaymentAndStatus() async {
    final payments = await _getPayments(widget.tenant['id']);
    DateTime? earliestDate;
    DateTime? farthestDate;

    for (final payment in payments) {
      final tanggalMasukDate =
          DateFormat('dd-MM-yyyy').parse(payment['tanggal_masuk'] as String);
      final tanggalHabisDate =
          DateFormat('dd-MM-yyyy').parse(payment['tanggal_habis'] as String);

      if (earliestDate == null || tanggalMasukDate.isBefore(earliestDate)) {
        earliestDate = tanggalMasukDate;
      }

      if (farthestDate == null || tanggalHabisDate.isAfter(farthestDate)) {
        farthestDate = tanggalHabisDate;
      }
    }

    _tanggalMasuk = earliestDate != null
        ? DateFormat('dd-MM-yyyy').format(earliestDate)
        : '-';
    _tanggalHabis = farthestDate != null
        ? DateFormat('dd-MM-yyyy').format(farthestDate)
        : '-';

    _statusPembayaran =
        payments.any((payment) => payment['status_pembayaran'] == 'Belum Lunas')
            ? 'Belum Lunas'
            : 'Lunas';
    _totalPayment =
        payments.fold(0, (sum, payment) => sum + int.parse(payment['tagihan']));

    await widget.dbHelper.updateTanggalAndBayar(widget.tenant['id'],
        _statusPembayaran, _totalPayment, _tanggalMasuk, _tanggalHabis);

    widget.reloadTenants();
    setState(() {});
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      int oldRoomId = widget.tenant['id_kamar'];

      await widget.dbHelper.updatePenghuniDenganGantiKamar(
        widget.tenant['id'],
        oldRoomId,
        {
          'nama': _nameController.text,
          'email': _emailController.text,
          'no_telp': _noTelpController.text,
          'tanggal_masuk': widget.tenant['tanggal_masuk'],
          'tanggal_habis': widget.tenant['tanggal_habis'],
          'id_kamar': int.parse(_selectedRoom!),
          'status_pembayaran': _statusPembayaran,
          'total_pembayaran': _totalPayment,
        },
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  Future<void> _showSaveConfirmationDialog() async {
    final confirmSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Anda yakin ingin menyimpan perubahan?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (confirmSave == true) {
      await _submitForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text(
          _isEditMode ? 'Edit Penghuni' : 'Detail Penghuni',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditMode) {
                _showSaveConfirmationDialog();
              } else {
                setState(() {
                  _isEditMode = true;
                });
              }
            },
          ),
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(() {
                  _initializeControllers();
                  _isEditMode = false;
                });
              },
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isEditMode ? _buildEditForm() : _buildTenantDetails(),
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nama'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama tidak boleh kosong';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email tidak boleh kosong';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _noTelpController,
            decoration: const InputDecoration(
              labelText: 'Nomor Telepon',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'No Telp tidak boleh kosong';
              } else if (value.length < 11 || value.length > 14) {
                return 'No Telp harus diantara 11-14';
              }
              return null;
            },
          ),
          DropdownButtonFormField<String>(
            value: _selectedRoom,
            items: _availableRooms.map((room) {
              return DropdownMenuItem<String>(
                value: room['id'].toString(),
                child: Text(room['nomor_kamar'].toString()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRoom = value;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Nomor Kamar',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kamar tidak boleh kosong';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getPayments(int tenantId) async {
    return await widget.dbHelper.queryPembayaranPenghuni(tenantId);
  }

  Widget _buildTenantDetails() {
    return SingleChildScrollView(
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
          Text('Tanggal Masuk: $_tanggalMasuk',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text('Tanggal Habis: $_tanggalHabis',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
              'Total Pembayaran: ${dbHelper.formatCurrency(_totalPayment.toString())}',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text('Nomor Kamar: ${widget.tenant['nomor_kamar']}',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text('Status Pembayaran: $_statusPembayaran',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Histori Pembayaran',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.add_card_sharp,
                  size: 40,
                ),
                onPressed: _showAddPaymentDialog,
              ),
            ],
          ),
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
                      return Dismissible(
                        key: Key(payment['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Konfirmasi Hapus'),
                                content: const Text(
                                    'Anda yakin ingin menghapus pembayaran ini?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) async {
                          await widget.dbHelper
                              .deletePembayaranPenghuni(payment['id']);
                          _updateTotalPaymentAndStatus();
                          setState(() {});
                        },
                        child: Card(
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
    );
  }
}
