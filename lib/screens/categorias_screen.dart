import 'package:flutter/material.dart';
import '../database/categoria_helper.dart';
import '../models/categoria.dart';
import '../utils/notifiers.dart';
import '../widgets/emoji_picker_field.dart';
import '../widgets/color_picker_field.dart';

// Helper de decoração utilizado pelos popups
InputDecoration _inputDec(BuildContext context, String hint) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.35)),
    filled: true,
    fillColor: cs.onSurface.withOpacity(0.06),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );
}

class CategoriasScreen extends StatefulWidget {
  final int usuarioId;

  const CategoriasScreen({super.key, required this.usuarioId});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  List<Categoria> _categorias = [];

  @override
  void initState() {
    super.initState();
    _carregar();
    categoriasNotifier.addListener(_carregar);
  }

  @override
  void dispose() {
    categoriasNotifier.removeListener(_carregar);
    super.dispose();
  }

  Future<void> _carregar() async {
    final lista = await CategoriaHelper.instance.buscarTodas(widget.usuarioId);
    if (!mounted) return;
    setState(() => _categorias = lista);
  }

  void _abrirCriar() {
    showDialog(
      context: context,
      builder: (_) => _PopupCriarCategoria(
        usuarioId: widget.usuarioId,
        onSalvar: (cat) async {
          await CategoriaHelper.instance.inserir(cat);
          _carregar();
        },
      ),
    );
  }

  void _abrirEditar(Categoria cat) {
    showDialog(
      context: context,
      builder: (_) => _PopupEditarCategoria(
        categoria: cat,
        onEditar: (atualizada) async {
          await CategoriaHelper.instance.atualizar(atualizada);
          _carregar();
        },
        onExcluir: () async {
          await CategoriaHelper.instance.excluir(cat.id!);
          _carregar();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Categorias',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Header button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: GestureDetector(
                onTap: _abrirCriar,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.onSurface.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add, color: cs.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Criar categoria',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Subtitle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Minhas categorias',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          // Grid of categories
          _categorias.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: const Center(child: CircularProgressIndicator()),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.crossAxisExtent < 600;
                      final crossAxisCount = isMobile ? 2 : 8;
                      final childAspectRatio = isMobile ? 2.5 : 1.2;
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: childAspectRatio,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final cat = _categorias[i];
                            return GestureDetector(
                              onTap: () => _abrirEditar(cat),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cs.onSurface.withOpacity(0.12)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: cs.onSurface.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(cat.icone, style: const TextStyle(fontSize: 16)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        cat.nome,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _categorias.length,
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Popup Criar ───────────────────────────────────────────────────────────────

class _PopupCriarCategoria extends StatefulWidget {
  final int usuarioId;
  final Future<void> Function(Categoria) onSalvar;

  const _PopupCriarCategoria({required this.usuarioId, required this.onSalvar});

  @override
  State<_PopupCriarCategoria> createState() => _PopupCriarCategoriaState();
}

class _PopupCriarCategoriaState extends State<_PopupCriarCategoria> {
  final _nomeController = TextEditingController();
  final _iconeController = TextEditingController();
  String? _corSelecionada;
  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _iconeController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nomeController.text.trim().isEmpty) return;
    setState(() => _salvando = true);

    try {
      final cat = Categoria(
        usuarioId: widget.usuarioId,
        nome: _nomeController.text.trim(),
        icone: _iconeController.text.trim().isEmpty
            ? '📦'
            : _iconeController.text.trim(),
        cor: _corSelecionada,
      );
      await widget.onSalvar(cat);
      categoriasNotifier.value++;
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Criar categoria',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Text(
                'Nome',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nomeController,
                decoration: _inputDec(context, 'Ex: Pets'),
                autofocus: true,
              ),
              const SizedBox(height: 14),
              Text(
                'Ícone (escolha um emoji)',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 6),
              EmojiPickerField(
                controller: _iconeController,
                hint: 'Ex: 🐶',
                inputDecoration: _inputDec,
              ),
              const SizedBox(height: 14),
              Text(
                'Cor (opcional)',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 6),
              ColorPickerField(
                selectedColor: _corSelecionada,
                onColorChanged: (cor) => setState(() => _corSelecionada = cor),
                hint: 'Digite em hexadecimal (ex: FF0000)',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _salvando ? null : _salvar,
                  child: _salvando
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Text(
                          'Salvar categoria',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Popup Editar ──────────────────────────────────────────────────────────────

class _PopupEditarCategoria extends StatefulWidget {
  final Categoria categoria;
  final Future<void> Function(Categoria) onEditar;
  final Future<void> Function() onExcluir;

  const _PopupEditarCategoria({
    required this.categoria,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  State<_PopupEditarCategoria> createState() => _PopupEditarCategoriaState();
}

class _PopupEditarCategoriaState extends State<_PopupEditarCategoria> {
  late final TextEditingController _nomeController;
  late final TextEditingController _iconeController;
  late String? _corSelecionada;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.categoria.nome);
    _iconeController = TextEditingController(text: widget.categoria.icone);
    _corSelecionada = widget.categoria.cor;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _iconeController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nomeController.text.trim().isEmpty) return;
    setState(() => _salvando = true);

    try {
      final atualizada = widget.categoria.copyWith(
        nome: _nomeController.text.trim(),
        icone: _iconeController.text.trim().isEmpty
            ? widget.categoria.icone
            : _iconeController.text.trim(),
        cor: _corSelecionada,
      );
      await widget.onEditar(atualizada);
      categoriasNotifier.value++;
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e')),
        );
      }
    }
  }

  Future<void> _excluir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir categoria'),
        content: const Text(
            'Tem certeza? Os gastos desta categoria não serão apagados.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir',
                style: TextStyle(color: Color(0xFFA32D2D))),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await widget.onExcluir();
        categoriasNotifier.value++;
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eFixa = widget.categoria.fixa;
    final cs = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Editar categoria',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Text(
                'Editar nome',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nomeController,
                enabled: !eFixa,
                decoration: _inputDec(context, 'Nome'),
              ),
              const SizedBox(height: 14),
              Text(
                'Editar ícone',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 6),
              EmojiPickerField(
                controller: _iconeController,
                hint: 'Emoji',
                inputDecoration: _inputDec,
              ),
              const SizedBox(height: 14),
              Text(
                'Editar cor (opcional)',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 6),
              ColorPickerField(
                selectedColor: _corSelecionada,
                onColorChanged: (cor) => setState(() => _corSelecionada = cor),
                hint: 'Digite em hexadecimal (ex: FF0000)',
              ),
              if (eFixa)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Categoria padrão — nome não pode ser alterado.',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withOpacity(0.35),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Editar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _salvando ? null : _salvar,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Color(0xFFA32D2D),
                      ),
                      label: const Text(
                        'Excluir',
                        style: TextStyle(color: Color(0xFFA32D2D)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFF09595)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: eFixa ? null : _excluir,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
