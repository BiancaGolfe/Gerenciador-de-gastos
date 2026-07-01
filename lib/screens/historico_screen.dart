import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/categoria_helper.dart';
import '../models/gasto.dart';
import '../models/categoria.dart';
import '../utils/formatters.dart';
import '../utils/notifiers.dart';
import '../widgets/gasto_card.dart';
import 'detalhe_screen.dart';

class HistoricoScreen extends StatefulWidget {
  final int usuarioId;

  const HistoricoScreen({super.key, required this.usuarioId});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen>
    with WidgetsBindingObserver {
  List<Gasto> _gastos = [];
  List<Categoria> _categoriasUsuario = [];
  String _filtro = 'Todos';
  final _db = DatabaseHelper.instance;
  final _agora = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _carregarCategorias();
    _carregar();
    // Escutar mudanças de categorias
    categoriasNotifier.addListener(_carregarCategorias);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    categoriasNotifier.removeListener(_carregarCategorias);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _carregarCategorias();
    }
  }

  Future<void> _carregarCategorias() async {
    final cats = await CategoriaHelper.instance.buscarTodas(widget.usuarioId);
    if (!mounted) return;
    setState(() => _categoriasUsuario = cats);
  }

  Future<void> _carregar() async {
    List<Gasto> gastos;
    if (_filtro == 'Todos') {
      gastos =
          await _db.buscarPorMes(_agora.year, _agora.month, widget.usuarioId);
    } else {
      gastos = await _db.buscarPorCategoria(_filtro, widget.usuarioId);
    }
    if (!mounted) return;
    setState(() => _gastos = gastos);
  }

  Map<String, List<Gasto>> _agruparPorDia() {
    final Map<String, List<Gasto>> agrupado = {};
    for (final g in _gastos) {
      final chave = formatarDiaMes(g.data);
      agrupado.putIfAbsent(chave, () => []).add(g);
    }
    return agrupado;
  }

  @override
  Widget build(BuildContext context) {
    final agrupado = _agruparPorDia();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Histórico',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(formatarMesAno(_agora),
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: cs.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Todos', ..._categoriasUsuario.map((c) => c.nome)]
                    .map((cat) {
                  final ativo = _filtro == cat;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _filtro = cat);
                      _carregar();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: ativo
                            ? cs.primary.withOpacity(0.12)
                            : cs.onSurface.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ativo ? cs.primary : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          color: ativo
                              ? cs.primary
                              : cs.onSurface.withOpacity(0.6),
                          fontWeight:
                              ativo ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _gastos.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum gasto encontrado.',
                      style: TextStyle(color: cs.onSurface.withOpacity(0.4)),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: agrupado.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 4),
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ),
                          ...entry.value.map(
                            (g) => GastoCard(
                              gasto: g,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => DetalheScreen(gasto: g)),
                                );
                                _carregar();
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
