import 'dart:async';
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
        id_kamar INTEGER  NOT NULL,
        nama TEXT NOT NULL,
        email TEXT NOT NULL,
        no_telp TEXT NOT NULL,
        status_pembayaran TEXT NOT NULL,
        tanggal_bayar TEXT,
        tagihan TEXT,
        tanggal_masuk TEXT NOT NULL,
        tanggal_habis TEXT NOT NULL,
        FOREIGN KEY (id_kamar) REFERENCES kamar (id)
      )
    ''');


    await db.execute('''
      CREATE TABLE riwayat_penghuni (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_penghuni INTEGER NOT NULL,
        id_kamar INTEGER NOT NULL,
        tanggal_masuk TEXT NOT NULL,
        tanggal_keluar TEXT,
        detail_pembayaran TEXT,
        catatan TEXT,
        FOREIGN KEY (id_penghuni) REFERENCES penghuni (id),
        FOREIGN KEY (id_kamar) REFERENCES kamar (id)
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


  Future<List<Map<String, dynamic>>> queryAllTenantsWithRoomNumbers() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT penghuni.id, penghuni.nama, penghuni.email, penghuni.no_telp, penghuni.id_kamar, penghuni.tanggal_masuk, penghuni.tanggal_habis, penghuni.tagihan, penghuni.tanggal_bayar, penghuni.status_pembayaran, kamar.nomor_kamar
      FROM penghuni
      JOIN kamar ON penghuni.id_kamar = kamar.id
    ''');
  }

  // CRUD operations for tenants
  Future<int> insertTenant(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('penghuni', row);
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

  Future<List<Map<String, dynamic>>> queryTenantHistory(int roomId) async {
    Database db = await database;
    return await db.query('riwayat_penghuni', where: 'id_kamar = ?', whereArgs: [roomId]);
  }
}
