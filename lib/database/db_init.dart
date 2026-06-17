import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Database? _db;

Future<Database>? _dbFuture;

Future<Database> getDatabase() async {
  if (kIsWeb) throw UnsupportedError('Use repositório em memória na web');
  _dbFuture ??= _initDB();
  return _dbFuture!;
}

Future<Database> _initDB() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'gastos.db');

  return openDatabase(
    path,
    version: 1,
    onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS gastos (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          valor       REAL NOT NULL,
          categoria   TEXT NOT NULL,
          descricao   TEXT,
          data        TEXT NOT NULL,
          imagem_path TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categorias (
          id    INTEGER PRIMARY KEY AUTOINCREMENT,
          nome  TEXT NOT NULL,
          icone TEXT NOT NULL,
          fixa  INTEGER NOT NULL DEFAULT 0
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
