import 'package:flutter/material.dart';
import 'package:aplikasi_kontrakan/database_helper.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
class ListPenghuni extends StatefulWidget {
  @override
  ListPenghuniState createState() => ListPenghuniState();
}

class ListPenghuniState extends State<ListPenghuni> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<void> _loadTenants() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Penghuni'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddTenantForm(context);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbHelper.queryAllTenantsWithRoomNumbers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final tenants = snapshot.data;
            return ListView.builder(
              itemCount: tenants?.length ?? 0,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('${tenants![index]['nama']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${tenants[index]['email']}'),
                      Text('Nomor Telp: ${tenants[index]['no_telp']}'),
                      Text('Nomor Kamar: ${tenants[index]['nomor_kamar']}'),
                      Text('Status Pembayaran: ${tenants[index]['status_pembayaran']}'),
                      Text('Tanggal Masuk: ${tenants[index]['tanggal_masuk']}'),
                      Text('Tanggal Habis: ${tenants[index]['tanggal_habis']}'),
                      Text(tenants[index]['status_pembayaran'] == 'penuh'?'Tanggal Bayar: ${tenants[index]['tanggal_bayar']}':'Tagihan: ${_formatCurrency(tenants[index]['tagihan'])}'),
                    ],
                  ),
                  onTap: () {
                    _showEditTenantForm(context, tenants[index]);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  String _formatCurrency(String value) {
    if (value.isEmpty) return '';
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    return formatter.format(int.parse(value));
  }

  Future<void> _showAddTenantForm(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddTenantForm(dbHelper: dbHelper)),
    );
    if (result == true) {
      _loadTenants();
    }
  }

  Future<void> _showEditTenantForm(BuildContext context, Map<String, dynamic> tenant) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditTenantForm(dbHelper: dbHelper, tenant: tenant)),
    );
    if (result == true) {
      _loadTenants();
    }
  }
}



class AddTenantForm extends StatefulWidget {
  final DatabaseHelper dbHelper;

  const AddTenantForm({super.key, required this.dbHelper});

  @override
  AddTenantFormState createState() => AddTenantFormState();
}

class AddTenantFormState extends State<AddTenantForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noTelpController = TextEditingController();
  final TextEditingController _tanggalMasukController = TextEditingController();
  final TextEditingController _tanggalHabisController = TextEditingController();
  final TextEditingController _tanggalBayarController = TextEditingController();
  final TextEditingController _tagihanController = TextEditingController();
  String? _selectedRoom;
  String? _paymentStatus;
  List<Map<String, dynamic>> _availableRooms = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableRooms();
  }

  Future<void> _loadAvailableRooms() async {
    final rooms = await widget.dbHelper.queryAllRooms();
    setState(() {
      _availableRooms = rooms.where((room) => room['status'] == 'kosong').toList();
      _availableRooms.sort((a, b) => a['nomor_kamar'].compareTo(b['nomor_kamar']));
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Penghuni'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
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
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _noTelpController,
                decoration: const InputDecoration(labelText: 'Nomor Telp'),
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
              TextFormField(
                controller: _tanggalMasukController,
                decoration: const InputDecoration(labelText: 'Tanggal Masuk'),
                readOnly: true,
                onTap: () => _selectDate(context, _tanggalMasukController),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal Masuk tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _tanggalHabisController,
                decoration: const InputDecoration(labelText: 'Tanggal Habis'),
                readOnly: true,
                onTap: () => _selectDate(context, _tanggalHabisController),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal Habis tidak boleh kosong';
                  }
                  // Convert the input strings to DateTime
                  DateTime tanggalMasuk = DateTime.parse(_tanggalMasukController.text);
                  DateTime tanggalHabis = DateTime.parse(value);

                  // Compare the dates
                  if (tanggalHabis.isBefore(tanggalMasuk)) {
                    return 'Tanggal Habis tidak boleh sebelum Tanggal Masuk';
                  }
                  return null;
                },
              ),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Nomor Kamar'),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pilih nomor kamar';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Status Pembayaran'),
                items: ['penuh', 'belum'].map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _paymentStatus = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pilih status pembayaran';
                  }
                  return null;
                },
              ),
              if (_paymentStatus == 'penuh')
                TextFormField(
                  controller: _tanggalBayarController,
                  decoration: const InputDecoration(labelText: 'Tanggal Bayar'),
                  readOnly: true,
                  onTap: () => _selectDate(context, _tanggalBayarController),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tanggal Bayar tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              if (_paymentStatus == 'belum')
                TextFormField(
                  controller: _tagihanController,
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      await widget.dbHelper.insertTenant({
        'nama': _nameController.text,
        'email': _emailController.text,
        'no_telp': _noTelpController.text,
        'tanggal_masuk': _tanggalMasukController.text,
        'tanggal_habis': _tanggalHabisController.text,
        'tanggal_bayar': _tanggalBayarController.text,
        'id_kamar': int.parse(_selectedRoom!),
        'status_pembayaran': _paymentStatus!,
        'tagihan': _tagihanController.text,
      });
      await widget.dbHelper.updateRoomStatus(int.parse(_selectedRoom!), _nameController.text);
      if (!context.mounted) return;
      Navigator.pop(context, true);
    }
  }
}

class EditTenantForm extends StatefulWidget {
  final DatabaseHelper dbHelper;
  final Map<String, dynamic> tenant;

  const EditTenantForm({super.key, required this.dbHelper, required this.tenant});

  @override
  EditTenantFormState createState() => EditTenantFormState();
}

class EditTenantFormState extends State<EditTenantForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noTelpController = TextEditingController();
  final TextEditingController _tanggalMasukController = TextEditingController();
  final TextEditingController _tanggalHabisController = TextEditingController();
  final TextEditingController _tanggalBayarController = TextEditingController();
  final TextEditingController _tagihanController = TextEditingController();
  String? _selectedRoom;
  String? _paymentStatus;
  List<Map<String, dynamic>> _availableRooms = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.tenant['nama'];
    _emailController.text = widget.tenant['email'];
    _noTelpController.text = widget.tenant['no_telp'];
    _tanggalMasukController.text = widget.tenant['tanggal_masuk'];
    _tanggalHabisController.text = widget.tenant['tanggal_habis'];
    _tanggalBayarController.text = widget.tenant['tanggal_bayar'] ?? '';
    _tagihanController.text = widget.tenant['tagihan'] ?? '';
    _selectedRoom = widget.tenant['nomor_kamar'].toString();
    _paymentStatus = widget.tenant['status_pembayaran'];
    _loadAvailableRooms();
  }

  Future<void> _loadAvailableRooms() async {
    final rooms = await widget.dbHelper.queryAllRooms();
    setState(() {
      _availableRooms = rooms.where((room) => room['status'] == 'kosong' || room['id'] == int.parse(_selectedRoom!)).toList();
      _availableRooms.sort((a, b) => a['nomor_kamar'].compareTo(b['nomor_kamar']));
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Penghuni'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
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
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _noTelpController,
                decoration: const InputDecoration(labelText: 'Nomor Telp'),
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
              TextFormField(
                controller: _tanggalMasukController,
                decoration: const InputDecoration(labelText: 'Tanggal Masuk'),
                readOnly: true,
                onTap: () => _selectDate(context, _tanggalMasukController),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal Masuk tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _tanggalHabisController,
                decoration: const InputDecoration(labelText: 'Tanggal Habis'),
                readOnly: true,
                onTap: () => _selectDate(context, _tanggalHabisController),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal Habis tidak boleh kosong';
                  }
                  // Convert the input strings to DateTime
                  DateTime tanggalMasuk = DateTime.parse(_tanggalMasukController.text);
                  DateTime tanggalHabis = DateTime.parse(value);

                  // Compare the dates
                  if (tanggalHabis.isBefore(tanggalMasuk)) {
                    return 'Tanggal Habis tidak boleh sebelum Tanggal Masuk';
                  }
                  return null;
                },
              ),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Nomor Kamar'),
                items: _availableRooms.map((room) {
                  return DropdownMenuItem<String>(
                    value: room['id'].toString(),
                    child: Text(room['nomor_kamar'].toString()),
                  );
                }).toList(),
                value: _selectedRoom,
                onChanged: (value) {
                  setState(() {
                    _selectedRoom = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pilih nomor kamar';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Status Pembayaran'),
                items: ['penuh', 'belum'].map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                value: _paymentStatus,
                onChanged: (value) {
                  setState(() {
                    _paymentStatus = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pilih status pembayaran';
                  }
                  return null;
                },
              ),
              if (_paymentStatus == 'penuh')
                TextFormField(
                  controller: _tanggalBayarController,
                  decoration: const InputDecoration(labelText: 'Tanggal Bayar'),
                  readOnly: true,
                  onTap: () => _selectDate(context, _tanggalBayarController),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tanggal Bayar tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              if (_paymentStatus == 'belum')
                TextFormField(
                  controller: _tagihanController,
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      int oldRoomId = widget.tenant['id_kamar'];

      await widget.dbHelper.updateTenantWithRoomChange(
        widget.tenant['id'],
        oldRoomId,
        {
          'nama': _nameController.text,
          'email': _emailController.text,
          'no_telp': _noTelpController.text,
          'tanggal_masuk': _tanggalMasukController.text,
          'tanggal_habis': _tanggalHabisController.text,
          'tanggal_bayar': _tanggalBayarController.text,
          'id_kamar': int.parse(_selectedRoom!),
          'status_pembayaran': _paymentStatus!,
          'tagihan': _tagihanController.text,
        },
      );

      if (!context.mounted) return;
      Navigator.pop(context, true);
    }
  }
}


