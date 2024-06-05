import 'dart:async';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'kontrak_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
  String formatCurrency(String value) {
    if (value.isEmpty) return '';
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    return formatter.format(int.parse(value));
  }
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE kamar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nomor_kamar INTEGER NOT NULL,
        lantai INTEGER NOT NULL,
        status TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE penghuni (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_kamar INTEGER,
        nama TEXT NOT NULL,
        email TEXT NOT NULL,
        no_telp TEXT NOT NULL,
        status_pembayaran TEXT NOT NULL,
        tagihan TEXT NOT NULL,
        tanggal_masuk TEXT NOT NULL,
        tanggal_habis TEXT,
        is_history BOOLEAN NOT NULL DEFAULT 0,
        FOREIGN KEY (id_kamar) REFERENCES kamar (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pembayaran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_penghuni INTEGER  NOT NULL,
        nominal TEXT NOT NULL,
        tanggal_bayar TEXT NOT NULL,
        FOREIGN KEY (id_penghuni) REFERENCES penghuni (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE riwayat_penghuni (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_penghuni INTEGER NOT NULL,
        tanggal_keluar TEXT NOT NULL,
        FOREIGN KEY (id_penghuni) REFERENCES penghuni (id)
      )
    ''');

    // Insert preset data
    for (int i = 1; i <= 8; i++) {
      await db.insert('kamar', {'nomor_kamar': i, 'lantai': 1, 'status': 'kosong'});
    }
    for (int i = 9; i <= 16; i++) {
      await db.insert('kamar', {'nomor_kamar': i, 'lantai': 2, 'status': 'kosong'});
    }
  }

  Future<List<Map<String, dynamic>>> queryAllRooms() async {
    Database db = await database;
    return await db.query('kamar');
  }
  Future<int> insertPayment(Map<String, dynamic> payment) async {
    var dbClient = await database;
    return await dbClient.insert('pembayaran', payment);
  }
  // CRUD operations for rooms
  Future<int> updateRoomStatus(int id, String status) async {
    Database db = await database;
    return await db.update(
      'kamar',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<int> deletePayment(int paymentId) async {
    Database db = await database;
    return await db.delete(
      'pembayaran',
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }
  Future<int> updatePayment(Map<String, dynamic> payment) async {
    var dbClient = await database;
    return await dbClient.update(
      'pembayaran',
      payment,
      where: 'id = ?',
      whereArgs: [payment['id']],
    );
  }

  Future<void> updateTenantWithRoomChange(int tenantId, int oldRoomId, Map<String, dynamic> row) async {
    Database db = await database;
    await db.transaction((txn) async {
      // Set the old room's status to 'kosong'
      await txn.update(
        'kamar',
        {'status': 'kosong'},
        where: 'id = ?',
        whereArgs: [oldRoomId],
      );
      // Update the tenant's record
      await txn.update(
        'penghuni',
        row,
        where: 'id = ?',
        whereArgs: [tenantId],
      );
      // Set the new room's status to 'occupied'
      await txn.update(
        'kamar',
        {'status': row['nama']},
        where: 'id = ?',
        whereArgs: [row['id_kamar']],
      );
    });
  }
  Future<List<Map<String, dynamic>>> queryTenantPayments(int tenantId) async {
    final db = await database;
    return await db.query(
      'pembayaran',
      where: 'id_penghuni = ?',
      whereArgs: [tenantId],
    );
  }


  Future<List<Map<String, dynamic>>> queryAllTenantsWithRoomNumbers() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT 
        penghuni.id, 
        penghuni.nama, 
        penghuni.email, 
        penghuni.no_telp, 
        penghuni.id_kamar, 
        penghuni.tanggal_masuk, 
        penghuni.tanggal_habis, 
        penghuni.tagihan, 
        penghuni.status_pembayaran, 
        kamar.nomor_kamar 
      FROM 
        penghuni 
      JOIN 
        kamar ON penghuni.id_kamar = kamar.id
      WHERE 
        penghuni.is_history = 0;
    ''');
  }

  // CRUD operations for tenants
  Future<int> insertTenant(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('penghuni', row);
  }
  Future<int> updatePaymentStatus(int idPenghuni, String statusPembayaran) async {
    final db = await database;
    return await db.update(
      'penghuni',
      {'status_pembayaran': statusPembayaran},
      where: 'id = ?',
      whereArgs: [idPenghuni],
    );
  }
  Future<List<Map<String, dynamic>>> queryAllTenants() async {
    Database db = await database;
    return await db.query('penghuni');
  }

  // CRUD operations for tenant history
  Future<int> insertTenantHistory(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('riwayat_penghuni', row);
  }

  Future<List<Map<String, dynamic>>> queryTenantHistory() async {
    Database db = await database;
    return await db.rawQuery('''
    SELECT 
        penghuni.id, 
        penghuni.nama, 
        penghuni.email, 
        penghuni.no_telp, 
        penghuni.id_kamar, 
        penghuni.tanggal_masuk, 
        riwayat_penghuni.tanggal_keluar, 
        penghuni.tagihan, 
        penghuni.status_pembayaran, 
        kamar.nomor_kamar 
    FROM 
        penghuni 
    JOIN 
        kamar ON penghuni.id_kamar = kamar.id 
    JOIN 
        riwayat_penghuni ON riwayat_penghuni.id_penghuni = penghuni.id
    WHERE 
        penghuni.is_history = 1
  ''');
  }

  Future<void> moveTenantToHistory(int tenantId) async {
    final db = await database;

    // Update tenant's `isHistory` status
    await db.update(
      'penghuni',
      {'is_history': 1},
      where: 'id = ?',
      whereArgs: [tenantId],
    );

    // Get tenant's information
    final tenant = await db.query(
      'penghuni',
      where: 'id = ?',
      whereArgs: [tenantId],
      limit: 1,
    );

    if (tenant.isNotEmpty) {
      final int idKamar = tenant[0]['id_kamar']as int;

      // Update the room status to 'kosong'
      await updateRoomStatus(idKamar, 'kosong');

      // Insert tenant history record
      await insertTenantHistory({
        'id_penghuni': tenantId,
        'tanggal_keluar': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });
    }
  }
}
