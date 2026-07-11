import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/usuario_helper.dart';
import '../models/gasto.dart';
import '../models/usuario.dart';
import '../utils/formatters.dart';
import '../utils/notifiers.dart';
import '../widgets/gasto_card.dart';
import '../database/categoria_helper.dart';
import '../models/categoria.dart';
import 'cadastro_screen.dart';
import 'detalhe_screen.dart';
import 'historico_screen.dart';
import 'graficos_screen.dart';
import 'categorias_screen.dart';
import 'login_screen.dart';
import '../utils/tema.dart';
import '../utils/meta_limite.dart';
import '../utils/notificacoes_meta.dart';

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
        onTap: (i) {
          setState(() => _abaSelecionada = i);
          
          if (i == 1) {
            categoriasNotifier.value++;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Início'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_outlined), label: 'Histórico'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline), label: 'Gráficos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined), label: 'Categorias'),
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
  double? _limite;
  MetaLimiteStatus _status = const MetaLimiteStatus(
    percentual: 0,
    perto: false,
    atingida: false,
    restante: 0,
  );
  final _db = DatabaseHelper.instance;
  DateTime _selecionado = mesSelecionado.value;

  String get _primeiroNome => widget.usuario?.nome.split(' ').first ?? '';

  Map<String, Categoria> _categoriasPorNome = {};

  @override
  void initState() {
    super.initState();
    mesSelecionado.addListener(_onMesChanged);
    
    gastosNotifier.addListener(_carregar);
    _carregar();
  }

  Future<double?> _carregarLimite() async {
    final limite = await MetaLimiteService.carregarLimite(widget.usuario?.id ?? 0);
    if (!mounted) return null;
    setState(() {
      _limite = limite;
    });
    return limite;
  }

  @override
  void dispose() {
    mesSelecionado.removeListener(_onMesChanged);
    gastosNotifier.removeListener(_carregar);
    super.dispose();
  }

  void _onMesChanged() {
    setState(() => _selecionado = mesSelecionado.value);
    _carregar();
  }

  Future<void> _carregar() async {
    final gastos = await _db.buscarPorMes(
      _selecionado.year, _selecionado.month, widget.usuario?.id ?? 0);
    final total = await _db.totalDoMes(
      _selecionado.year, _selecionado.month, widget.usuario?.id ?? 0);
    if (!mounted) return;
    final totalGastosMes = gastos.length;
    await _carregarCategorias();
    final limite = await _carregarLimite();
    if (!mounted) return;
    setState(() {
      _gastos = gastos.take(5).toList();
      _total = total;
      _status = MetaLimiteService.calcularStatus(_total, limite);
    });
    await MetaNotificationService.avaliarEExibir(
      usuarioId: widget.usuario?.id ?? 0,
      limite: limite,
      gastoAtual: _total,
      status: _status,
      totalGastosMes: totalGastosMes,
    );
  }

  Future<void> _carregarCategorias() async {
    final categorias = await CategoriaHelper.instance
        .buscarTodas(widget.usuario?.id ?? 0);
    if (!mounted) return;
    setState(() {
      _categoriasPorNome = {
        for (final cat in categorias) cat.nome: cat,
      };
    });
  }

  Future<void> _editarLimite() async {
    final controller = TextEditingController(text: _limite?.toStringAsFixed(2));
    final valor = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Definir meta de gastos'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Limite mensal',
              hintText: 'Ex.: 2500',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final valorDigitado = double.tryParse(controller.text.replaceAll(',', '.'));
                if (valorDigitado != null && valorDigitado > 0) {
                  Navigator.pop(context, valorDigitado);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (valor == null) return;
    await MetaLimiteService.salvarLimite(valor, widget.usuario?.id ?? 0);
    if (!mounted) return;
    setState(() {
      _limite = valor;
      _status = MetaLimiteService.calcularStatus(_total, _limite);
    });
  }

  Future<void> _limparLimite() async {
    await MetaLimiteService.limparLimite(widget.usuario?.id ?? 0);
    if (!mounted) return;
    setState(() {
      _limite = null;
      _status = MetaLimiteService.calcularStatus(_total, _limite);
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
              'Resumo de ${formatarMesAno(_selecionado)}',
              style:
                  TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
        actions: [
          
          ValueListenableBuilder<bool>(
            valueListenable: temaEscuro,
            builder: (_, escuro, __) => IconButton(
              icon: Icon(
                escuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
              onPressed: () => temaEscuro.value = !temaEscuro.value,
            ),
          ),
          
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selecionado,
                firstDate: DateTime(2000),
                lastDate: DateTime(DateTime.now().year + 5),
                helpText: 'Escolha mês/ano',
              );
              if (picked != null) {
                mesSelecionado.value = DateTime(picked.year, picked.month, 1);
              }
            },
          ),
          
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
                          MaterialPageRoute(
                              builder: (_) => HomeScreen(usuario: u)),
                        );
                      }
                    },
                    child: Text(
                      'Entrar',
                      style: TextStyle(
                          color: cs.primary, fontWeight: FontWeight.w600),
                    ),
                  )
                : PopupMenuButton(
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        onTap: widget.onSair,
                        child: const Row(
                          children: [
                            Icon(Icons.logout_outlined,
                                size: 18, color: Color(0xFFA32D2D)),
                            SizedBox(width: 8),
                            Text('Sair',
                                style: TextStyle(color: Color(0xFFA32D2D))),
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
              builder: (_) =>
                  CadastroScreen(usuarioId: widget.usuario?.id ?? 0),
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
              _CartaoResumo(
                total: _total,
                mes: _selecionado,
                limite: _limite,
                status: _status,
                onEditarLimite: _editarLimite,
                onLimparLimite: _limparLimite,
              ),
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
  final double? limite;
  final MetaLimiteStatus status;
  final VoidCallback onEditarLimite;
  final VoidCallback onLimparLimite;

  const _CartaoResumo({
    required this.total,
    required this.mes,
    required this.limite,
    required this.status,
    required this.onEditarLimite,
    required this.onLimparLimite,
  });

  @override
  Widget build(BuildContext context) {
    final corAlerta = status.atingida
        ? const Color(0xFFFF6B6B)
        : status.perto
            ? const Color(0xFFFFD166)
            : Colors.white70;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total em ${formatarMesAno(mes)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.tune, color: Colors.white),
                onSelected: (value) {
                  if (value == 'editar') {
                    onEditarLimite();
                  } else if (value == 'limpar') {
                    onLimparLimite();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: const [
                        Icon(Icons.flag_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Definir limite'),
                      ],
                    ),
                  ),
                  if (limite != null)
                    const PopupMenuItem(
                      value: 'limpar',
                      child: Row(
                        children: [
                          Icon(Icons.clear, size: 18),
                          SizedBox(width: 8),
                          Text('Remover limite'),
                        ],
                      ),
                    ),
                ],
              ),
            ],
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
          if (limite != null) ...[
            const SizedBox(height: 12),
            Text(
              status.atingida
                  ? 'Você já passou do seu limite mensal.'
                  : status.perto
                      ? 'Você está perto do limite do limite.'
                      : 'Limite mensal definida.',
              style: TextStyle(color: corAlerta, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Limite: ${formatarMoeda(limite!)} • Restante: ${formatarMoeda(status.restante)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Text(
              'Use o botão de ajustes para criar um limite mensal.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
