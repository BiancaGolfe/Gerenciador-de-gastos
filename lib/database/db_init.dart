import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';

Future<Database>? _dbFuture;

Future<Database> getDatabase() async {
  _dbFuture ??= _initDB();
  return _dbFuture!;
}

Future<Database> _initDB() async {

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    bool isDesktop = false;
    
    try {
      isDesktop = !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.macOS ||
           defaultTargetPlatform == TargetPlatform.linux);
    } catch (_) {}

    if (isDesktop) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  final path = kIsWeb ? 'gastos.db' : join(await getDatabasesPath(), 'gastos.db');

  return openDatabase(
    path,
    version: 3,
    onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS gastos (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          usuario_id  INTEGER NOT NULL,
          valor       REAL NOT NULL,
          categoria   TEXT NOT NULL,
          descricao   TEXT,
          data        TEXT NOT NULL,
          imagem_path TEXT,
          FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categorias (
          id         INTEGER PRIMARY KEY AUTOINCREMENT,
          usuario_id INTEGER,
          nome       TEXT NOT NULL,
          icone      TEXT NOT NULL,
          fixa       INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS usuarios (
          id    INTEGER PRIMARY KEY AUTOINCREMENT,
          nome  TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          senha TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sessao (
          id         INTEGER PRIMARY KEY,
          usuario_id INTEGER NOT NULL
        )
      ''');
      for (final c in _categoriasFixas) {
        await db.insert('categorias', c);
      }
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        // Migração v1 -> v2: adicionar usuario_id aos gastos
        await db.execute('ALTER TABLE gastos ADD COLUMN usuario_id INTEGER');
        await db.execute('UPDATE gastos SET usuario_id = 1 WHERE usuario_id IS NULL');
        await db.execute('''
          CREATE TABLE gastos_new (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario_id  INTEGER NOT NULL,
            valor       REAL NOT NULL,
            categoria   TEXT NOT NULL,
            descricao   TEXT,
            data        TEXT NOT NULL,
            imagem_path TEXT,
            FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          INSERT INTO gastos_new (id, usuario_id, valor, categoria, descricao, data, imagem_path)
          SELECT id, COALESCE(usuario_id, 1), valor, categoria, descricao, data, imagem_path FROM gastos
        ''');
        await db.execute('DROP TABLE gastos');
        await db.execute('ALTER TABLE gastos_new RENAME TO gastos');
      }
      if (oldVersion < 3) {
        // Migração v2 -> v3: adicionar usuario_id às categorias
        await db.execute('ALTER TABLE categorias ADD COLUMN usuario_id INTEGER');
        // Deixar categorias fixas (fixa=1) com usuario_id=NULL, e demais com usuario_id=1
        // (considera que antigas categorias criadas pertencem ao primeiro usuário)
      }
    },
  );
}

const _categoriasFixas = [
  {'nome': 'Alimentação', 'icone': '🍽️', 'fixa': 0},
  {'nome': 'Transporte',  'icone': '🚌', 'fixa': 0},
  {'nome': 'Lazer',       'icone': '🎮', 'fixa': 0},
  {'nome': 'Estudos',     'icone': '📚', 'fixa': 0},
  {'nome': 'Saúde',       'icone': '❤️', 'fixa': 0},
  {'nome': 'Outros',      'icone': '📦', 'fixa': 0},
];