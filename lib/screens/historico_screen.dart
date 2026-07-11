import 'dart:collection';
import 'package:flutter/material.dart';
import '../database/categoria_helper.dart';
import '../database/database_helper.dart';
import '../models/categoria.dart';
import '../models/gasto.dart';
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
  List<String> _categoriasDaBarra = [];
  String _filtro = 'Todos';
  final _db = DatabaseHelper.instance;
  DateTime _selecionado = mesSelecionado.value;
  Map<String, Categoria> _categoriasPorNome = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    mesSelecionado.addListener(_onMesChanged);
    _carregar();
    
    gastosNotifier.addListener(_carregar);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    mesSelecionado.removeListener(_onMesChanged);
    gastosNotifier.removeListener(_carregar);
    super.dispose();
  }

  void _onMesChanged() {
    setState(() => _selecionado = mesSelecionado.value);
    _carregar();
  }

  Future<void> _carregarCategorias() async {
    final categorias = await CategoriaHelper.instance.buscarTodas(widget.usuarioId);
    if (!mounted) return;
    setState(() {
      _categoriasPorNome = {
        for (final cat in categorias) cat.nome: cat,
      };
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _carregar();
    }
  }

  Future<void> _carregar() async {
    final todosGastosDoMes = await _db.buscarPorMes(
      _selecionado.year,
      _selecionado.month,
      widget.usuarioId,
    );

    final gastos = _filtro == 'Todos'
        ? todosGastosDoMes
        : todosGastosDoMes.where((g) => g.categoria == _filtro).toList();

    if (!mounted) return;
    final categorias = LinkedHashSet<String>.from(
      todosGastosDoMes.map((g) => g.categoria).where((c) => c.trim().isNotEmpty),
    ).toList();
    await _carregarCategorias();

    if (_filtro != 'Todos' && !categorias.contains(_filtro)) {
      setState(() => _filtro = 'Todos');
      await _carregar();
      return;
    }

    setState(() {
      _gastos = gastos;
      _categoriasDaBarra = categorias;
    });
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
            Text(formatarMesAno(_selecionado),
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selecionado,
                firstDate: DateTime(2000),
                lastDate: DateTime(DateTime.now().year + 5),
                helpText:
                    'Escolha mês/ano',
              );
              if (picked != null) {
                mesSelecionado.value = DateTime(picked.year, picked.month, 1);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: cs.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final filtros = [
                  'Todos',
                  ..._categoriasDaBarra,
                ];

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: filtros.map((cat) {
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
                );
              },
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
                            (g) {
                            final categoria = _categoriasPorNome[g.categoria];
                            return GastoCard(
                              gasto: g,
                              categoriaEmoji: categoria?.icone,
                              categoriaCorFundo: categoria?.corFundo != null
                                  ? Color(int.parse('0xFF${categoria!.corFundo}'))
                                  : null,
                              categoriaCor: categoria?.cor != null
                                  ? Color(int.parse('0xFF${categoria!.cor}'))
                                  : null,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => DetalheScreen(gasto: g)),
                                );
                                _carregar();
                              },
                            );
                          },
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
