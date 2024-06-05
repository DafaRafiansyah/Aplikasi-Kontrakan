import 'package:flutter/material.dart';
import 'package:aplikasi_kontrakan/database_helper.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _tagihanController = TextEditingController();
  String? _selectedRoom;
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
      setState(() {
        controller.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text(
          'Tambah Penghuni',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Padding(
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
                    labelText: 'Nomor Telpon',
                    
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
                TextFormField(
                  controller: _tanggalMasukController,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Masuk',
                   
                  ),
                  
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
                decoration: const InputDecoration(
                  labelText: 'Tanggal Habis',
                ),
                
                readOnly: true,
                onTap: () => _selectDate(context, _tanggalHabisController),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal Habis tidak boleh kosong';
                  }
                  DateTime tanggalMasuk = DateTime.parse(_tanggalMasukController.text);
                  DateTime tanggalHabis = DateTime.parse(value);
                  if (tanggalHabis.isBefore(tanggalMasuk)) {
                    return 'Tanggal Habis tidak boleh sebelum Tanggal Masuk';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Nomor Kamar',
                   
                  ),
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
                TextFormField(
                  controller: _tagihanController,
                  decoration: const InputDecoration(
                    labelText: 'Tagihan',
                   
                  ),
                  
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), backgroundColor: Colors.blueGrey,
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  onPressed: _submitForm,
                  child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
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
        'id_kamar': int.parse(_selectedRoom!),
        'status_pembayaran': 'belum lunas',
        'tagihan': _tagihanController.text,
      });
      await widget.dbHelper.updateRoomStatus(int.parse(_selectedRoom!), _nameController.text);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }
}