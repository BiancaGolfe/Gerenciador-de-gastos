import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../models/gasto.dart';
import '../utils/categorias.dart';
import '../utils/formatters.dart';

class GraficosScreen extends StatefulWidget {
  final int usuarioId;

  const GraficosScreen({super.key, required this.usuarioId});

  @override
  State<GraficosScreen> createState() => _GraficosScreenState();
}

class _GraficosScreenState extends State<GraficosScreen> {
  List<Gasto> _gastos = [];
  double _total = 0;
  final _agora = DateTime.now();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final gastos = await DatabaseHelper.instance.buscarPorMes(_agora.year, _agora.month, widget.usuarioId);
    final total = gastos.fold(0.0, (s, g) => s + g.valor);
    if (!mounted) return;
    setState(() {
      _gastos = gastos;
      _total = total;
    });
  }

  Map<String, double> _porCategoria() {
    final Map<String, double> mapa = {};
    for (final g in _gastos) {
      mapa[g.categoria] = (mapa[g.categoria] ?? 0) + g.valor;
    }
    final entries = mapa.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  @override
  Widget build(BuildContext context) {
    final porCat = _porCategoria();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gráficos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(
              '${formatarMesAno(_agora)} — ${formatarMoeda(_total)}',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      ),
      body: _gastos.isEmpty
          ? Center(child: Text('Nenhum dado ainda.', style: TextStyle(color: cs.onSurface.withOpacity(0.4))))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _CartaoSecao(
                  titulo: 'Por categoria',
                  child: Column(
                    children: porCat.entries.map((e) {
                      final info = categoriaInfo(e.key);
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
                                      decoration: BoxDecoration(color: info.cor, shape: BoxShape.circle),
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
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor: cs.onSurface.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation(info.cor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                if (porCat.isNotEmpty)
                  _CartaoSecao(
                    titulo: 'Distribuição',
                    child: SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: porCat.entries.map((e) {
                            final info = categoriaInfo(e.key);
                            final pct = _total > 0 ? (e.value / _total) * 100 : 0.0;
                            return PieChartSectionData(
                              value: e.value,
                              color: info.cor,
                              title: '${pct.toStringAsFixed(0)}%',
                              radius: 60,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _CartaoSecao extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _CartaoSecao({required this.titulo, required this.child});

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
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
