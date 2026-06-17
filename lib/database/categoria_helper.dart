import 'package:flutter/foundation.dart';
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
  Future<List<Categoria>> buscarTodas();
  Future<Categoria> inserir(Categoria cat);
  Future<int> atualizar(Categoria cat);
  Future<int> excluir(int id);
}

class _SqfliteCatRepo implements _CatRepo {
  @override
  Future<List<Categoria>> buscarTodas() async {
    final db = await getDatabase();
    final rows = await db.query('categorias', orderBy: 'id ASC');
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
    return db.update('categorias', cat.toMap(), where: 'id = ?', whereArgs: [cat.id]);
  }

  @override
  Future<int> excluir(int id) async {
    final db = await getDatabase();
    return db.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }
}

class _MemoryCatRepo implements _CatRepo {
  final List<Categoria> _lista = [];
  int _nextId = 1;

  _MemoryCatRepo() {
    for (final c in _fixas) {
      _lista.add(Categoria(
        id: _nextId++,
        nome: c['nome']!,
        icone: c['icone']!,
        fixa: false,
      ));
    }
  }

  @override
  Future<List<Categoria>> buscarTodas() async => List.from(_lista);

  @override
  Future<Categoria> inserir(Categoria cat) async {
    final novo = cat.copyWith(id: _nextId++);
    _lista.add(novo);
    return novo;
  }

  @override
  Future<int> atualizar(Categoria cat) async {
    final i = _lista.indexWhere((c) => c.id == cat.id);
    if (i == -1) return 0;
    _lista[i] = cat;
    return 1;
  }

  @override
  Future<int> excluir(int id) async {
    final before = _lista.length;
    _lista.removeWhere((c) => c.id == id);
    return _lista.length < before ? 1 : 0;
  }
}

class CategoriaHelper {
  static final CategoriaHelper instance = CategoriaHelper._();
  late final _CatRepo _repo;

  CategoriaHelper._() {
    _repo = kIsWeb ? _MemoryCatRepo() : _SqfliteCatRepo();
  }

  Future<List<Categoria>> buscarTodas() => _repo.buscarTodas();
  Future<Categoria> inserir(Categoria cat) => _repo.inserir(cat);
  Future<int> atualizar(Categoria cat) => _repo.atualizar(cat);
  Future<int> excluir(int id) => _repo.excluir(id);
}
