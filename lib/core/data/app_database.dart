import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'petcare.db');
    return openDatabase(
      path,
      version: 10,
      onCreate: (db, _) => _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              "ALTER TABLE vets_cache ADD COLUMN services TEXT NOT NULL DEFAULT ''");
          await db.execute(
              "ALTER TABLE vets_cache ADD COLUMN hours_weekdays TEXT NOT NULL DEFAULT '08:30 – 19:00'");
          await db.execute(
              "ALTER TABLE vets_cache ADD COLUMN hours_saturday TEXT NOT NULL DEFAULT '09:00 – 13:00'");
          await db.execute(
              "ALTER TABLE vets_cache ADD COLUMN phone TEXT NOT NULL DEFAULT ''");
        }
        if (oldVersion < 3) {
          await db.execute(
              'ALTER TABLE medical_documents ADD COLUMN file_path TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE vets_cache ADD COLUMN latitude REAL');
          await db.execute('ALTER TABLE vets_cache ADD COLUMN longitude REAL');
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              email TEXT NOT NULL UNIQUE,
              phone TEXT NOT NULL DEFAULT '',
              role TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              email TEXT NOT NULL UNIQUE,
              phone TEXT NOT NULL DEFAULT '',
              role TEXT NOT NULL
            )
          ''');
          await _addColumnIfMissing(
              db, 'users', 'password_hash', "TEXT NOT NULL DEFAULT ''");
          await _addColumnIfMissing(
              db, 'users', 'password_salt', "TEXT NOT NULL DEFAULT ''");
        }
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS health_tips_cache (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              species TEXT NOT NULL,
              tip_text TEXT NOT NULL,
              source TEXT NOT NULL,
              fetched_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 8) {
          await _addColumnIfMissing(
              db, 'users', 'address', "TEXT NOT NULL DEFAULT ''");
          await _addColumnIfMissing(db, 'users', 'latitude', 'REAL');
          await _addColumnIfMissing(db, 'users', 'longitude', 'REAL');
        }
        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS accessories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              category TEXT NOT NULL,
              species TEXT NOT NULL,
              price REAL NOT NULL,
              description TEXT NOT NULL DEFAULT '',
              emoji TEXT NOT NULL DEFAULT '🛍️',
              stock INTEGER NOT NULL DEFAULT 10
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cart_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              owner_id TEXT NOT NULL,
              accessory_id INTEGER NOT NULL,
              quantity INTEGER NOT NULL DEFAULT 1
            )
          ''');
        }
        if (oldVersion < 10) {
          await _addColumnIfMissing(db, 'users', 'photo_path', 'TEXT');
        }
      },
    );
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (exists) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL DEFAULT '',
        role TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        address TEXT NOT NULL DEFAULT '',
        latitude REAL,
        longitude REAL,
        photo_path TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE pets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id TEXT NOT NULL,
        name TEXT NOT NULL,
        species TEXT NOT NULL,
        breed TEXT NOT NULL,
        age TEXT NOT NULL,
        weight REAL NOT NULL,
        sex TEXT NOT NULL,
        emoji TEXT NOT NULL,
        color_hex INTEGER NOT NULL,
        birth_date TEXT NOT NULL,
        chip TEXT NOT NULL,
        sterilized INTEGER NOT NULL,
        photo_path TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE vaccines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        next_date TEXT NOT NULL,
        vet TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE treatments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        current_day INTEGER NOT NULL,
        total_days INTEGER NOT NULL,
        icon_code INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE medical_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_hex INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE medical_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        size TEXT NOT NULL,
        is_pdf INTEGER NOT NULL,
        file_path TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE vets_cache (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        specialty TEXT NOT NULL,
        clinic TEXT NOT NULL,
        address TEXT NOT NULL,
        rating REAL NOT NULL,
        reviews INTEGER NOT NULL,
        distance TEXT NOT NULL,
        experience INTEGER NOT NULL,
        available_today INTEGER NOT NULL,
        color_hex INTEGER NOT NULL,
        price TEXT NOT NULL,
        image TEXT,
        services TEXT NOT NULL DEFAULT '',
        hours_weekdays TEXT NOT NULL DEFAULT '08:30 – 19:00',
        hours_saturday TEXT NOT NULL DEFAULT '09:00 – 13:00',
        phone TEXT NOT NULL DEFAULT '',
        latitude REAL,
        longitude REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vet_id TEXT NOT NULL,
        pet_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        day TEXT NOT NULL,
        month TEXT NOT NULL,
        time TEXT NOT NULL,
        reason TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        time TEXT NOT NULL,
        food TEXT NOT NULL,
        quantity TEXT NOT NULL,
        calories INTEGER NOT NULL,
        done INTEGER NOT NULL,
        icon_code INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE food_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL,
        note TEXT NOT NULL,
        allowed INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE diets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL UNIQUE,
        diet_type TEXT NOT NULL,
        goal TEXT NOT NULL,
        meals_per_day INTEGER NOT NULL,
        notes TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        time_label TEXT NOT NULL,
        type TEXT NOT NULL,
        unread INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE custom_reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        repeat_mode TEXT NOT NULL,
        note TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE health_tips_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        species TEXT NOT NULL,
        tip_text TEXT NOT NULL,
        source TEXT NOT NULL,
        fetched_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE accessories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        species TEXT NOT NULL,
        price REAL NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        emoji TEXT NOT NULL DEFAULT '🛍️',
        stock INTEGER NOT NULL DEFAULT 10
      )
    ''');
    await db.execute('''
      CREATE TABLE cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id TEXT NOT NULL,
        accessory_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }
}
