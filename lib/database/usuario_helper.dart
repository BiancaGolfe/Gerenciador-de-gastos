import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import 'db_init.dart';

abstract class _UsuarioRepo {
  Future<Usuario?> buscarLogado();
  Future<Usuario?> buscarPorEmail(String email);
  Future<Usuario> inserir(Usuario usuario);
  Future<void> salvarSessao(int id);
  Future<void> encerrarSessao();
}

// ── Mobile: SQFlite ───────────────────────────────────────────────────────────

class _SqfliteUsuarioRepo implements _UsuarioRepo {
  @override
  Future<Usuario?> buscarLogado() async {
    final db = await getDatabase();
    final sessao = await db.query('sessao', limit: 1);
    if (sessao.isEmpty) return null;
    final uid = sessao.first['usuario_id'] as int;
    final rows = await db.query('usuarios', where: 'id = ?', whereArgs: [uid]);
    if (rows.isEmpty) return null;
    return Usuario.fromMap(rows.first);
  }

  @override
  Future<Usuario?> buscarPorEmail(String email) async {
    final db = await getDatabase();
    final rows = await db.query('usuarios', where: 'email = ?', whereArgs: [email]);
    if (rows.isEmpty) return null;
    return Usuario.fromMap(rows.first);
  }

  @override
  Future<Usuario> inserir(Usuario usuario) async {
    final db = await getDatabase();
    final id = await db.insert('usuarios', usuario.toMap());
    return Usuario(id: id, nome: usuario.nome, email: usuario.email, senha: usuario.senha);
  }

  @override
  Future<void> salvarSessao(int id) async {
    final db = await getDatabase();
    await db.delete('sessao');
    await db.insert('sessao', {'id': 1, 'usuario_id': id});
  }

  @override
  Future<void> encerrarSessao() async {
    final db = await getDatabase();
    await db.delete('sessao');
  }
}

// ── Web: memória + SharedPreferences para sessão ──────────────────────────────

class _WebUsuarioRepo implements _UsuarioRepo {
  final List<Usuario> _usuarios = [];
  int _nextId = 1;

  @override
  Future<Usuario?> buscarLogado() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('sessao_id');
    if (id == null) return null;
    final email = prefs.getString('sessao_email');
    final nome = prefs.getString('sessao_nome');
    final senha = prefs.getString('sessao_senha');
    if (email == null || nome == null || senha == null) return null;
    return Usuario(id: id, nome: nome, email: email, senha: senha);
  }

  @override
  Future<Usuario?> buscarPorEmail(String email) async {
    return _usuarios.where((u) => u.email == email).firstOrNull;
  }

  @override
  Future<Usuario> inserir(Usuario usuario) async {
    final novo = Usuario(
      id: _nextId++,
      nome: usuario.nome,
      email: usuario.email,
      senha: usuario.senha,
    );
    _usuarios.add(novo);
    return novo;
  }

  @override
  Future<void> salvarSessao(int id) async {
    final usuario = _usuarios.firstWhere((u) => u.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sessao_id', id);
    await prefs.setString('sessao_email', usuario.email);
    await prefs.setString('sessao_nome', usuario.nome);
    await prefs.setString('sessao_senha', usuario.senha);
  }

  @override
  Future<void> encerrarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sessao_id');
    await prefs.remove('sessao_email');
    await prefs.remove('sessao_nome');
    await prefs.remove('sessao_senha');
  }
}

// ── Fachada ───────────────────────────────────────────────────────────────────

class UsuarioHelper {
  static final UsuarioHelper instance = UsuarioHelper._();
  late final _UsuarioRepo _repo;

  UsuarioHelper._() {
    _repo = kIsWeb ? _WebUsuarioRepo() : _SqfliteUsuarioRepo();
  }

  Future<Usuario?> buscarLogado() => _repo.buscarLogado();
  Future<Usuario?> buscarPorEmail(String email) => _repo.buscarPorEmail(email);
  Future<Usuario> inserir(Usuario u) => _repo.inserir(u);
  Future<void> salvarSessao(int id) => _repo.salvarSessao(id);
  Future<void> encerrarSessao() => _repo.encerrarSessao();
}
