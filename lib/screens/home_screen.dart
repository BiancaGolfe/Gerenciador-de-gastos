import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/usuario_helper.dart';
import '../models/gasto.dart';
import '../models/usuario.dart';
import '../utils/formatters.dart';
import '../widgets/gasto_card.dart';
import 'cadastro_screen.dart';
import 'detalhe_screen.dart';
import 'historico_screen.dart';
import 'graficos_screen.dart';
import 'categorias_screen.dart';
import 'login_screen.dart';
import '../utils/tema.dart';

class HomeScreen extends StatefulWidget {
  final Usuario? usuario;
  const HomeScreen({super.key, this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _abaSelecionada = 0;

  Future<void> _sair() async {
    await UsuarioHelper.instance.encerrarSessao();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _abaSelecionada,
        children: [
          _HomeTab(usuario: widget.usuario, onSair: _sair),
          HistoricoScreen(usuarioId: widget.usuario?.id ?? 0),
          GraficosScreen(usuarioId: widget.usuario?.id ?? 0),
          CategoriasScreen(usuarioId: widget.usuario?.id ?? 0),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _abaSelecionada,
        onTap: (i) => setState(() => _abaSelecionada = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.list_outlined), label: 'Histórico'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: 'Gráficos'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: 'Categorias'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final Usuario? usuario;
  final VoidCallback onSair;

  const _HomeTab({required this.usuario, required this.onSair});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<Gasto> _gastos = [];
  double _total = 0;
  final _db = DatabaseHelper.instance;
  final _agora = DateTime.now();

  String get _primeiroNome => widget.usuario?.nome.split(' ').first ?? '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final gastos = await _db.buscarPorMes(_agora.year, _agora.month, widget.usuario?.id ?? 0);
    final total = await _db.totalDoMes(_agora.year, _agora.month, widget.usuario?.id ?? 0);
    if (!mounted) return;
    setState(() {
      _gastos = gastos.take(5).toList();
      _total = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.usuario != null ? 'Olá, $_primeiroNome!' : 'Olá!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              'Resumo de ${formatarMesAno(_agora)}',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
        actions: [
          // Botão tema escuro/claro
          ValueListenableBuilder<bool>(
            valueListenable: temaEscuro,
            builder: (_, escuro, __) => IconButton(
              icon: Icon(
                escuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
              onPressed: () => temaEscuro.value = !temaEscuro.value,
            ),
          ),
          // Avatar / Entrar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: widget.usuario == null
                ? TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                      final u = await UsuarioHelper.instance.buscarLogado();
                      if (!mounted) return;
                      if (u != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => HomeScreen(usuario: u)),
                        );
                      }
                    },
                    child: Text(
                      'Entrar',
                      style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
                    ),
                  )
                : PopupMenuButton(
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        onTap: widget.onSair,
                        child: const Row(
                          children: [
                            Icon(Icons.logout_outlined, size: 18, color: Color(0xFFA32D2D)),
                            SizedBox(width: 8),
                            Text('Sair', style: TextStyle(color: Color(0xFFA32D2D))),
                          ],
                        ),
                      ),
                    ],
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: cs.primary.withOpacity(0.12),
                      child: Text(
                        _primeiroNome[0].toUpperCase(),
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: cs.primary,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CadastroScreen(usuarioId: widget.usuario?.id ?? 0),
            ),
          );
          _carregar();
        },
        child: Icon(Icons.add, color: cs.onPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CartaoResumo(total: _total, mes: _agora),
              const SizedBox(height: 20),
              const Text('Recentes',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              if (_gastos.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Nenhum gasto este mês.\nToque em + para adicionar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurface.withOpacity(0.4)),
                    ),
                  ),
                )
              else
                ..._gastos.map(
                  (g) => GastoCard(
                    gasto: g,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DetalheScreen(gasto: g)),
                      );
                      _carregar();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoResumo extends StatelessWidget {
  final double total;
  final DateTime mes;

  const _CartaoResumo({required this.total, required this.mes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF534AB7), Color(0xFF3C3489)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total em ${formatarMesAno(mes)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            formatarMoeda(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
