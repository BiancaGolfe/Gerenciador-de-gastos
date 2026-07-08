import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../database/categoria_helper.dart';
import '../models/gasto.dart';
import '../models/categoria.dart';
import '../utils/categorias.dart';
import '../utils/formatters.dart';
import '../utils/notifiers.dart';

enum _TipoGrafico { rosca, coluna }

Color _parseHexColor(String? hex) {
  final raw = (hex ?? '').trim().replaceFirst('#', '').toUpperCase();
  if (raw.isEmpty) return Colors.grey;
  var normalized = raw;
  if (normalized.length == 3) {
    normalized = normalized.split('').expand((c) => [c, c]).join();
  }
  if (normalized.length != 6) return Colors.grey;

  try {
    return Color(int.parse('FF$normalized', radix: 16));
  } catch (_) {
    return Colors.grey;
  }
}

Color resolverCorCategoria({
  required String nomeCategoria,
  required List<Categoria> categorias,
}) {
  final nome = nomeCategoria.trim().toLowerCase();
  Categoria? categoria;
  for (final item in categorias) {
    if (item.nome.trim().toLowerCase() == nome) {
      categoria = item;
      break;
    }
  }

  if (categoria?.cor != null && categoria!.cor!.trim().isNotEmpty) {
    final cor = _parseHexColor(categoria.cor);
    if (cor != Colors.grey || categoria.cor!.trim().length == 6) {
      return cor;
    }
  }

  final info = categoriaInfo(nomeCategoria);
  if (info.nome == nomeCategoria) {
    return info.cor;
  }

  final hash =
      nome.codeUnits.fold<int>(0, (acc, unit) => (acc * 31 + unit) & 0xFFFFFF);
  return Color(0xFF000000 | hash);
}

class GraficosScreen extends StatefulWidget {
  final int usuarioId;

  const GraficosScreen({super.key, required this.usuarioId});

  @override
  State<GraficosScreen> createState() => _GraficosScreenState();
}

class _GraficosScreenState extends State<GraficosScreen> {
  List<Gasto> _gastos = [];
  List<Gasto> _gastosAno = [];
  List<Categoria> _categorias = [];
  double _total = 0;
  double _totalAno = 0;
  DateTime _selecionado = mesSelecionado.value;
  _TipoGrafico _graficoMensal = _TipoGrafico.rosca;
  _TipoGrafico _graficoAnual = _TipoGrafico.rosca;

  @override
  void initState() {
    super.initState();
    mesSelecionado.addListener(_onMesChanged);
    _carregar();
    _carregarCategorias();
    // Escutar mudanças de gastos e categorias
    gastosNotifier.addListener(_carregar);
    categoriasNotifier.addListener(_carregarCategorias);
  }

  @override
  void dispose() {
    mesSelecionado.removeListener(_onMesChanged);
    gastosNotifier.removeListener(_carregar);
    categoriasNotifier.removeListener(_carregarCategorias);
    super.dispose();
  }

  void _onMesChanged() {
    setState(() => _selecionado = mesSelecionado.value);
    _carregar();
  }

  Future<void> _carregarCategorias() async {
    final cats = await CategoriaHelper.instance.buscarTodas(widget.usuarioId);
    if (!mounted) return;
    setState(() => _categorias = cats);
  }

  Future<void> _carregar() async {
    final gastos = await DatabaseHelper.instance
        .buscarPorMes(_selecionado.year, _selecionado.month, widget.usuarioId);
    final total = gastos.fold(0.0, (s, g) => s + g.valor);
    if (!mounted) return;
    setState(() {
      _gastos = gastos;
      _total = total;
    });
    await _carregarAno();
  }

  Future<void> _carregarAno() async {
    final List<Gasto> todos = [];
    for (var m = 1; m <= 12; m++) {
      final lista = await DatabaseHelper.instance
          .buscarPorMes(_selecionado.year, m, widget.usuarioId);
      todos.addAll(lista);
    }
    final totalAno = todos.fold(0.0, (s, g) => s + g.valor);
    if (!mounted) return;
    setState(() {
      _gastosAno = todos;
      _totalAno = totalAno;
    });
  }

  Map<String, double> _porCategoria() {
    final Map<String, double> mapa = {};
    for (final g in _gastos) {
      mapa[g.categoria] = (mapa[g.categoria] ?? 0) + g.valor;
    }
    final entries = mapa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  Map<String, double> _porCategoriaAno() {
    final Map<String, double> mapa = {};
    for (final g in _gastosAno) {
      mapa[g.categoria] = (mapa[g.categoria] ?? 0) + g.valor;
    }
    final entries = mapa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  Color _getCor(String nomeCategoria) {
    return resolverCorCategoria(
      nomeCategoria: nomeCategoria,
      categorias: _categorias,
    );
  }

  void _alternarGraficoMensal() {
    setState(() {
      _graficoMensal = _graficoMensal == _TipoGrafico.rosca
          ? _TipoGrafico.coluna
          : _TipoGrafico.rosca;
    });
  }

  void _alternarGraficoAnual() {
    setState(() {
      _graficoAnual = _graficoAnual == _TipoGrafico.rosca
          ? _TipoGrafico.coluna
          : _TipoGrafico.rosca;
    });
  }

  Widget _botaoTipoGrafico({
    required _TipoGrafico tipoAtual,
    required VoidCallback onPressed,
  }) {
    final exibindoRosca = tipoAtual == _TipoGrafico.rosca;
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: exibindoRosca ? 'Ver gráfico de coluna' : 'Ver gráfico de rosca',
      icon: Icon(
        exibindoRosca ? Icons.bar_chart_outlined : Icons.donut_large_outlined,
        size: 20,
      ),
      onPressed: onPressed,
    );
  }

  Widget _graficoRosca({
    required Map<String, double> dados,
    required double total,
    required double altura,
    required double raio,
    required double centro,
  }) {
    return Center(
      child: SizedBox(
        height: altura,
        child: PieChart(
          PieChartData(
            sections: dados.entries.map((e) {
              final pct = total > 0 ? (e.value / total) * 100 : 0.0;
              return PieChartSectionData(
                value: e.value,
                color: _getCor(e.key),
                title: '${pct.toStringAsFixed(0)}%',
                radius: raio,
                titleStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              );
            }).toList(),
            sectionsSpace: 2,
            centerSpaceRadius: centro,
          ),
        ),
      ),
    );
  }

  double _intervaloEixoDinamico(double maiorValor) {
    if (maiorValor <= 0) return 1.0;
    final alvo = maiorValor / 6;
    const opcoes = [25.0, 50.0, 100.0, 150.0, 200.0, 250.0, 500.0, 1000.0];
    for (final opcao in opcoes) {
      if (alvo <= opcao) return opcao;
    }
    return (alvo / 1000).ceil() * 1000.0;
  }

  Widget _graficoColuna({
    required Map<String, double> dados,
    required double total,
    required double altura,
    required bool mostrarLegenda,
    double? intervaloEixo,
    bool maximoExato = false,
  }) {
    final entries = dados.entries.toList();
    final maiorValor = entries.fold<double>(0, (maior, e) => e.value > maior ? e.value : maior);
    final espacamentoPorBarra = entries.length <= 4
      ? 74.0
      : entries.length <= 7
        ? 62.0
        : entries.length <= 10
          ? 52.0
          : 44.0;
    final largura = entries.isEmpty
      ? 260.0
      : (entries.length * espacamentoPorBarra).clamp(260.0, 620.0).toDouble();
    final intervalo = intervaloEixo != null && intervaloEixo > 0
        ? intervaloEixo
        : _intervaloEixoDinamico(maiorValor);
    final maxY = maiorValor <= 0
        ? intervalo
        : maximoExato
            ? maiorValor
            : (maiorValor * 1.15 / intervalo).ceil() * intervalo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: SizedBox(
            height: altura,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Center(
                child: SizedBox(
                  width: largura,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final item = entries[group.x.toInt()];
                            return BarTooltipItem(
                              '${item.key}\n${formatarMoeda(item.value)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            interval: intervalo,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  value.round().toString(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: intervalo,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: entries.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: item.value,
                              width: 18,
                              borderRadius: BorderRadius.circular(6),
                              color: _getCor(item.key),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (mostrarLegenda) ...[
          const SizedBox(height: 12),
          ...entries.map((e) {
            final pct = total > 0 ? e.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: _getCor(e.key), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(e.key, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  Text(
                    '${formatarMoeda(e.value)}  (${(pct * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final porCat = _porCategoria();
    final porCatAno = _porCategoriaAno();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gráficos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(
              '${formatarMesAno(_selecionado)} — ${formatarMoeda(_total)}',
              style:
                  TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5)),
            ),
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
                helpText: 'Escolha mês/ano (selecione qualquer dia do mês desejado)',
              );
              if (picked != null) {
                mesSelecionado.value = DateTime(picked.year, picked.month, 1);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Seção mensal: mostra mensagem se não houver gastos no mês
          if (_gastos.isEmpty)
            _CartaoSecao(
              titulo: 'Por categoria',
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('Nenhum gasto neste mês selecionado.',
                      style:
                          TextStyle(color: cs.onSurface.withOpacity(0.5))),
                ),
              ),
            )
          else
            _CartaoSecao(
              titulo: 'Por categoria',
              child: Column(
                children: porCat.entries.map((e) {
                  final pct = _total > 0 ? e.value / _total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: _getCor(e.key),
                                      shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Text(e.key, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                            Text(
                              formatarMoeda(e.value),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: cs.onSurface.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation(_getCor(e.key)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
          // Distribuição mensal (apenas quando há dados)
          if (porCat.isNotEmpty)
            _CartaoSecao(
              titulo: 'Distribuição',
              trailing: _botaoTipoGrafico(
                tipoAtual: _graficoMensal,
                onPressed: _alternarGraficoMensal,
              ),
              child: _graficoMensal == _TipoGrafico.rosca
                  ? _graficoRosca(
                      dados: porCat,
                      total: _total,
                      altura: 200,
                      raio: 60,
                      centro: 40,
                    )
                  : _graficoColuna(
                      dados: porCat,
                      total: _total,
                      altura: 220,
                      mostrarLegenda: false,
                    ),
            ),
          const SizedBox(height: 16),
          // Seção anual: sempre visível
          _CartaoSecao(
            titulo: 'Distribuição anual',
            trailing: _botaoTipoGrafico(
              tipoAtual: _graficoAnual,
              onPressed: _alternarGraficoAnual,
            ),
            child: Column(
              children: [
                if (porCatAno.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Nenhum gasto no ano selecionado.',
                        style: TextStyle(color: cs.onSurface.withOpacity(0.5))),
                  )
                else if (_graficoAnual == _TipoGrafico.rosca) ...[
                  _graficoRosca(
                    dados: porCatAno,
                    total: _totalAno,
                    altura: 180,
                    raio: 50,
                    centro: 36,
                  ),
                  const SizedBox(height: 12),
                  ...porCatAno.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: _getCor(e.key), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(e.key, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                          Text(
                            formatarMoeda(e.value),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  _graficoColuna(
                    dados: porCatAno,
                    total: _totalAno,
                    altura: 220,
                    mostrarLegenda: true,
                    intervaloEixo: 500,
                    maximoExato: false,
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoSecao extends StatelessWidget {
  final String titulo;
  final Widget? trailing;
  final Widget child;

  const _CartaoSecao({required this.titulo, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
