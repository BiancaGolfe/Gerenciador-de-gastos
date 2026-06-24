import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/categoria.dart';
import 'db_init.dart';

const _fixas = [
  {'nome': 'Alimentação', 'icone': '🍽️'},
  {'nome': 'Transporte',  'icone': '🚌'},
  {'nome': 'Lazer',       'icone': '🎮'},
  {'nome': 'Estudos',     'icone': '📚'},
  {'nome': 'Saúde',       'icone': '❤️'},
  {'nome': 'Outros',      'icone': '📦'},
];

abstract class _CatRepo {
  Future<List<Categoria>> buscarTodas(int usuarioId);
  Future<Categoria> inserir(Categoria cat);
  Future<int> atualizar(Categoria cat);
  Future<int> excluir(int id);
}

class _SqfliteCatRepo implements _CatRepo {
  @override
  Future<List<Categoria>> buscarTodas(int usuarioId) async {
    final db = await getDatabase();
   
    final rows = await db.query('categorias',
        where: 'usuario_id IS NULL OR usuario_id = ?',
        whereArgs: [usuarioId],
        orderBy: 'id ASC');
    return rows.map(Categoria.fromMap).toList();
  }

  @override
  Future<Categoria> inserir(Categoria cat) async {
    final db = await getDatabase();
    final id = await db.insert('categorias', cat.toMap());
    return cat.copyWith(id: id);
  }

  @override
  Future<int> atualizar(Categoria cat) async {
    final db = await getDatabase();
    return db.update('categorias', cat.toMap(),
        where: 'id = ?', whereArgs: [cat.id]);
  }

  @override
  Future<int> excluir(int id) async {
    final db = await getDatabase();
    return db.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }
}


class _WebCatRepo implements _CatRepo {
  static const _key = 'categorias_data';
  static const _nextIdKey = 'categorias_next_id';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> _loadAll() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> _saveAll(List<Map<String, dynamic>> lista) async {
    final prefs = await _prefs;
    await prefs.setString(_key, jsonEncode(lista));
  }

  Future<int> _nextId() async {
    final prefs = await _prefs;
    final id = prefs.getInt(_nextIdKey) ?? 1;
    await prefs.setInt(_nextIdKey, id + 1);
    return id;
  }

 
  Future<void> _inicializarFixas() async {
    final all = await _loadAll();
    if (all.isNotEmpty) return;
    final prefs = await _prefs;
    int nextId = 1;
    final lista = <Map<String, dynamic>>[];
    for (final c in _fixas) {
      lista.add({'id': nextId++, 'usuario_id': null, 'nome': c['nome'], 'icone': c['icone'], 'fixa': 0});
    }
    await prefs.setString(_key, jsonEncode(lista));
    await prefs.setInt(_nextIdKey, nextId);
  }

  @override
  Future<List<Categoria>> buscarTodas(int usuarioId) async {
    await _inicializarFixas();
    final all = await _loadAll();
    
    return all
        .where((cat) => cat['usuario_id'] == null || cat['usuario_id'] == usuarioId)
        .map(Categoria.fromMap)
        .toList();
  }

  @override
  Future<Categoria> inserir(Categoria cat) async {
    await _inicializarFixas();
    final id = await _nextId();
    final novo = cat.copyWith(id: id);
    final all = await _loadAll();
    all.add(novo.toMap());
    await _saveAll(all);
    return novo;
  }

  @override
  Future<int> atualizar(Categoria cat) async {
    final all = await _loadAll();
    final i = all.indexWhere((m) => m['id'] == cat.id);
    if (i == -1) return 0;
    all[i] = cat.toMap();
    await _saveAll(all);
    return 1;
  }

  @override
  Future<int> excluir(int id) async {
    final all = await _loadAll();
    final before = all.length;
    all.removeWhere((m) => m['id'] == id);
    if (all.length == before) return 0;
    await _saveAll(all);
    return 1;
  }
}

class CategoriaHelper {
  static final CategoriaHelper instance = CategoriaHelper._();
  late final _CatRepo _repo;

  CategoriaHelper._() {
    _repo = _SqfliteCatRepo();
  }

  Future<List<Categoria>> buscarTodas(int usuarioId) => _repo.buscarTodas(usuarioId);
  Future<Categoria> inserir(Categoria cat) => _repo.inserir(cat);
  Future<int> atualizar(Categoria cat) => _repo.atualizar(cat);
  Future<int> excluir(int id) => _repo.excluir(id);
}