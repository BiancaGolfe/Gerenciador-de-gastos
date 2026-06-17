import 'package:flutter/foundation.dart';
import '../models/gasto.dart';
import 'db_init.dart';

abstract class _GastoRepo {
  Future<Gasto> inserir(Gasto gasto);
  Future<List<Gasto>> buscarPorMes(int ano, int mes);
  Future<List<Gasto>> buscarPorCategoria(String categoria);
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
  Future<List<Gasto>> buscarPorMes(int ano, int mes) async {
    final db = await getDatabase();
    final inicio = DateTime(ano, mes, 1).toIso8601String();
    final fim = DateTime(ano, mes + 1, 0, 23, 59, 59).toIso8601String();
    final result = await db.query('gastos',
        where: 'data BETWEEN ? AND ?',
        whereArgs: [inicio, fim],
        orderBy: 'data DESC');
    return result.map(Gasto.fromMap).toList();
  }

  @override
  Future<List<Gasto>> buscarPorCategoria(String categoria) async {
    final db = await getDatabase();
    final result = await db.query('gastos',
        where: 'categoria = ?', whereArgs: [categoria], orderBy: 'data DESC');
    return result.map(Gasto.fromMap).toList();
  }

  @override
  Future<int> atualizar(Gasto gasto) async {
    final db = await getDatabase();
    return db.update('gastos', gasto.toMap(), where: 'id = ?', whereArgs: [gasto.id]);
  }

  @override
  Future<int> excluir(int id) async {
    final db = await getDatabase();
    return db.delete('gastos', where: 'id = ?', whereArgs: [id]);
  }
}

class _MemoryRepo implements _GastoRepo {
  final List<Gasto> _gastos = [];
  int _nextId = 1;

  @override
  Future<Gasto> inserir(Gasto gasto) async {
    final novo = gasto.copyWith(id: _nextId++);
    _gastos.add(novo);
    return novo;
  }

  @override
  Future<List<Gasto>> buscarPorMes(int ano, int mes) async {
    return _gastos
        .where((g) => g.data.year == ano && g.data.month == mes)
        .toList()
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  @override
  Future<List<Gasto>> buscarPorCategoria(String categoria) async {
    return _gastos
        .where((g) => g.categoria == categoria)
        .toList()
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  @override
  Future<int> atualizar(Gasto gasto) async {
    final i = _gastos.indexWhere((g) => g.id == gasto.id);
    if (i == -1) return 0;
    _gastos[i] = gasto;
    return 1;
  }

  @override
  Future<int> excluir(int id) async {
    final before = _gastos.length;
    _gastos.removeWhere((g) => g.id == id);
    return _gastos.length < before ? 1 : 0;
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  late final _GastoRepo _repo;

  DatabaseHelper._() {
    _repo = kIsWeb ? _MemoryRepo() : _SqfliteRepo();
  }

  Future<Gasto> inserir(Gasto gasto) => _repo.inserir(gasto);
  Future<List<Gasto>> buscarPorMes(int ano, int mes) => _repo.buscarPorMes(ano, mes);
  Future<List<Gasto>> buscarPorCategoria(String cat) => _repo.buscarPorCategoria(cat);
  Future<int> atualizar(Gasto gasto) => _repo.atualizar(gasto);
  Future<int> excluir(int id) => _repo.excluir(id);

  Future<double> totalDoMes(int ano, int mes) async {
    final gastos = await buscarPorMes(ano, mes);
    return gastos.fold<double>(0.0, (soma, g) => soma + g.valor);
  }
}
