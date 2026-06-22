import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import 'db_init.dart';

const _sessaoKey = 'sessao_usuario_id';

abstract class _UsuarioRepo {
  Future<Usuario?> buscarLogado();
  Future<Usuario?> buscarPorEmail(String email);
  Future<Usuario> inserir(Usuario usuario);
  Future<void> salvarSessao(int id);
  Future<void> encerrarSessao();
}

// ── Mobile: SQFlite ───────────────────────────────────────────────────────────

class _SqfliteUsuarioRepo implements _UsuarioRepo {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<Usuario?> buscarLogado() async {
    final db = await getDatabase();
    final sessao = await db.query('sessao', limit: 1);
    int? uid;
    if (sessao.isNotEmpty) {
      uid = sessao.first['usuario_id'] as int?;
    }
    if (uid == null) {
      final prefs = await _prefs;
      uid = prefs.getInt(_sessaoKey);
    }
    if (uid == null) return null;

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
    return Usuario(
      id: id,
      nome: usuario.nome,
      email: usuario.email,
      senha: usuario.senha,
    );
  }

  @override
  Future<void> salvarSessao(int id) async {
    final db = await getDatabase();
    await db.delete('sessao');
    await db.insert('sessao', {'id': 1, 'usuario_id': id});
    final prefs = await _prefs;
    await prefs.setInt(_sessaoKey, id);
  }

  @override
  Future<void> encerrarSessao() async {
    final db = await getDatabase();
    await db.delete('sessao');
    final prefs = await _prefs;
    await prefs.remove(_sessaoKey);
  }
}

// ── Web: localStorage via shared_preferences ──────────────────────────────────

class _WebUsuarioRepo implements _UsuarioRepo {
  static const _usuariosKey = 'usuarios_data';
  static const _nextIdKey = 'usuarios_next_id';
  static const _sessaoKey = 'sessao_usuario_id';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> _loadAll() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_usuariosKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> _saveAll(List<Map<String, dynamic>> lista) async {
    final prefs = await _prefs;
    await prefs.setString(_usuariosKey, jsonEncode(lista));
  }

  Future<int> _nextId() async {
    final prefs = await _prefs;
    final id = prefs.getInt(_nextIdKey) ?? 1;
    await prefs.setInt(_nextIdKey, id + 1);
    return id;
  }

  @override
  Future<Usuario?> buscarLogado() async {
    final prefs = await _prefs;
    final uid = prefs.getInt(_sessaoKey);
    if (uid == null) return null;
    final all = await _loadAll();
    final map = all.where((m) => m['id'] == uid).firstOrNull;
    if (map == null) return null;
    return Usuario.fromMap(map);
  }

  @override
  Future<Usuario?> buscarPorEmail(String email) async {
    final all = await _loadAll();
    final map = all.where((m) => m['email'] == email).firstOrNull;
    if (map == null) return null;
    return Usuario.fromMap(map);
  }

  @override
  Future<Usuario> inserir(Usuario usuario) async {
    final id = await _nextId();
    final novo = Usuario(
      id: id,
      nome: usuario.nome,
      email: usuario.email,
      senha: usuario.senha,
    );
    final all = await _loadAll();
    all.add(novo.toMap());
    await _saveAll(all);
    return novo;
  }

  @override
  Future<void> salvarSessao(int id) async {
    final prefs = await _prefs;
    await prefs.setInt(_sessaoKey, id);
  }

  @override
  Future<void> encerrarSessao() async {
    final prefs = await _prefs;
    await prefs.remove(_sessaoKey);
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