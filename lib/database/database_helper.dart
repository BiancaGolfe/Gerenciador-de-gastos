import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gasto.dart';
import 'db_init.dart';

abstract class _GastoRepo {
  Future<Gasto> inserir(Gasto gasto);
  Future<List<Gasto>> buscarPorMes(int ano, int mes, int usuarioId);
  Future<List<Gasto>> buscarPorCategoria(String categoria, int usuarioId);
  Future<int> atualizar(Gasto gasto);
  Future<int> excluir(int id);
}

class _SqfliteRepo implements _GastoRepo {
  @override
  Future<Gasto> inserir(Gasto gasto) async {
    final db = await getDatabase();
    final id = await db.insert('gastos', gasto.toMap());
    return gasto.copyWith(id: id);
  }

  @override
  Future<List<Gasto>> buscarPorMes(int ano, int mes, int usuarioId) async {
    final db = await getDatabase();
    final inicio = DateTime(ano, mes, 1).toIso8601String();
    final fim = DateTime(ano, mes + 1, 0, 23, 59, 59).toIso8601String();
    final result = await db.query('gastos',
        where: 'usuario_id = ? AND data BETWEEN ? AND ?',
        whereArgs: [usuarioId, inicio, fim],
        orderBy: 'data DESC');
    return result.map(Gasto.fromMap).toList();
  }

  @override
  Future<List<Gasto>> buscarPorCategoria(String categoria, int usuarioId) async {
    final db = await getDatabase();
    final result = await db.query('gastos',
        where: 'usuario_id = ? AND categoria = ?', 
        whereArgs: [usuarioId, categoria], 
        orderBy: 'data DESC');
    return result.map(Gasto.fromMap).toList();
  }

  @override
  Future<int> atualizar(Gasto gasto) async {
    final db = await getDatabase();
    return db.update('gastos', gasto.toMap(),
        where: 'id = ?', whereArgs: [gasto.id]);
  }

  @override
  Future<int> excluir(int id) async {
    final db = await getDatabase();
    return db.delete('gastos', where: 'id = ?', whereArgs: [id]);
  }
}

/// Repositório para web: persiste gastos no localStorage do navegador
/// via shared_preferences, para os dados sobreviverem ao recarregamento da página.
class _WebLocalStorageRepo implements _GastoRepo {
  static const _keystoreKey = 'gastos_data';
  static const _nextIdKey = 'gastos_next_id';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> _loadAll() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keystoreKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> _saveAll(List<Map<String, dynamic>> gastos) async {
    final prefs = await _prefs;
    await prefs.setString(_keystoreKey, jsonEncode(gastos));
  }

  Future<int> _nextId() async {
    final prefs = await _prefs;
    final id = (prefs.getInt(_nextIdKey) ?? 1);
    await prefs.setInt(_nextIdKey, id + 1);
    return id;
  }

  @override
  Future<Gasto> inserir(Gasto gasto) async {
    final id = await _nextId();
    final novo = gasto.copyWith(id: id);
    final all = await _loadAll();
    all.add(novo.toMap());
    await _saveAll(all);
    return novo;
  }

  @override
  Future<List<Gasto>> buscarPorMes(int ano, int mes, int usuarioId) async {
    final all = await _loadAll();
    final gastos = all
        .map(Gasto.fromMap)
        .where((g) => g.usuarioId == usuarioId && g.data.year == ano && g.data.month == mes)
        .toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    return gastos;
  }

  @override
  Future<List<Gasto>> buscarPorCategoria(String categoria, int usuarioId) async {
    final all = await _loadAll();
    final gastos = all
        .map(Gasto.fromMap)
        .where((g) => g.usuarioId == usuarioId && g.categoria == categoria)
        .toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    return gastos;
  }

  @override
  Future<int> atualizar(Gasto gasto) async {
    final all = await _loadAll();
    final i = all.indexWhere((m) => m['id'] == gasto.id);
    if (i == -1) return 0;
    all[i] = gasto.toMap();
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

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  late final _GastoRepo _repo;

  DatabaseHelper._() {
    _repo = kIsWeb ? _WebLocalStorageRepo() : _SqfliteRepo();
  }

  Future<Gasto> inserir(Gasto gasto) => _repo.inserir(gasto);
  Future<List<Gasto>> buscarPorMes(int ano, int mes, int usuarioId) =>
      _repo.buscarPorMes(ano, mes, usuarioId);
  Future<List<Gasto>> buscarPorCategoria(String cat, int usuarioId) =>
      _repo.buscarPorCategoria(cat, usuarioId);
  Future<int> atualizar(Gasto gasto) => _repo.atualizar(gasto);
  Future<int> excluir(int id) => _repo.excluir(id);

  Future<double> totalDoMes(int ano, int mes, int usuarioId) async {
    final gastos = await buscarPorMes(ano, mes, usuarioId);
    return gastos.fold<double>(0.0, (soma, g) => soma + g.valor);
  }
}