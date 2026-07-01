import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_helper.dart';
import '../database/categoria_helper.dart';
import '../models/gasto.dart';
import '../models/categoria.dart';
import '../utils/formatters.dart';
import '../utils/image_helper.dart';
import '../utils/image_helper_web.dart'
    if (dart.library.io) '../utils/image_helper_stub.dart';
import '../widgets/emoji_picker_field.dart';
import '../widgets/color_picker_field.dart';
import 'graficos_screen.dart';

class CadastroScreen extends StatefulWidget {
  final Gasto? gastoParaEditar;
  final int usuarioId;

  const CadastroScreen(
      {super.key, this.gastoParaEditar, required this.usuarioId});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();
  String? _categoriaSelecionada;
  DateTime _dataSelecionada = DateTime.now();
  String? _imagemPath;
  bool _salvando = false;
  List<Categoria> _categorias = [];

  bool get _editando => widget.gastoParaEditar != null;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
    if (_editando) {
      final g = widget.gastoParaEditar!;
      _valorController.text = _formatarValorInicial(g.valor);
      _descricaoController.text = g.descricao ?? '';
      _categoriaSelecionada = g.categoria;
      _dataSelecionada = g.data;
      _imagemPath = g.imagemPath;
    }
  }

  Future<void> _carregarCategorias() async {
    final lista = await CategoriaHelper.instance.buscarTodas(widget.usuarioId);
    if (!mounted) return;
    setState(() {
      _categorias = lista;
      _categoriaSelecionada ??= lista.isNotEmpty ? lista.first.nome : null;
    });
  }

  @override
  void dispose() {
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _escolherImagem(ImageSource source) async {
    final path = await selecionarImagem(source);
    if (path != null) setState(() => _imagemPath = path);
  }

  void _mostrarOpcoesImagem() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tirar foto'),
              onTap: () async {
                Navigator.pop(context);
                if (kIsWeb) {
                  final path = await tirarFotoWeb();
                  if (path != null) setState(() => _imagemPath = path);
                } else {
                  _escolherImagem(ImageSource.camera);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(context);
                _escolherImagem(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Converte double para string mascarada: 1050.5 → "1.050,50"
  String _formatarValorInicial(double v) {
    final centavos = (v * 100).round().toString().padLeft(3, '0');
    final dec = centavos.substring(centavos.length - 2);
    var intPart = centavos
        .substring(0, centavos.length - 2)
        .replaceFirst(RegExp(r'^0+'), '');
    if (intPart.isEmpty) intPart = '0';
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write('.');
      buf.write(intPart[i]);
    }
    return '$buf,$dec';
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSelecionada == null) return;
    setState(() => _salvando = true);

    // Remove pontos de milhar e troca vírgula por ponto para parsear
    final valorTexto =
        _valorController.text.replaceAll('.', '').replaceAll(',', '.');
    final valor = double.tryParse(valorTexto) ?? 0;

    final gasto = Gasto(
      id: widget.gastoParaEditar?.id,
      usuarioId: widget.usuarioId,
      valor: valor,
      categoria: _categoriaSelecionada!,
      descricao: _descricaoController.text.trim().isEmpty
          ? null
          : _descricaoController.text.trim(),
      data: _dataSelecionada,
      imagemPath: _imagemPath,
    );

    if (_editando) {
      await DatabaseHelper.instance.atualizar(gasto);
    } else {
      await DatabaseHelper.instance.inserir(gasto);
    }

    // Notificar gráfico para atualizar
    gastosNotifier.value++;

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _abrirCriarCategoria() {
    showDialog(
      context: context,
      builder: (_) => _PopupCriarCategoriaInline(
        usuarioId: widget.usuarioId,
        onSalvar: (cat) async {
          final nova = await CategoriaHelper.instance.inserir(cat);
          await _carregarCategorias();
          setState(() => _categoriaSelecionada = nova.nome);
        },
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.35)),
      filled: true,
      fillColor: cs.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.onSurface.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.onSurface.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(_editando ? 'Editar gasto' : 'Novo gasto'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FotoArea(imagemPath: _imagemPath, onTap: _mostrarOpcoesImagem),
              const SizedBox(height: 16),
              _Label('Valor (R\$)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _valorController,
                keyboardType: TextInputType.number,
                inputFormatters: [_MoedaFormatter()],
                decoration: _inputDecoration(context, '0,00'),
                validator: (v) {
                  if (v == null || v.isEmpty || v == '0,00')
                    return 'Informe o valor';
                  final num = double.tryParse(
                    v.replaceAll('.', '').replaceAll(',', '.'),
                  );
                  if (num == null || num <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _Label('Categoria'),
              const SizedBox(height: 8),
              if (_categorias.isEmpty)
                const CircularProgressIndicator()
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._categorias.map((cat) {
                      final selecionada = _categoriaSelecionada == cat.nome;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _categoriaSelecionada = cat.nome),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selecionada
                                ? cs.primary.withOpacity(0.12)
                                : cs.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selecionada
                                  ? cs.primary
                                  : cs.onSurface.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat.icone,
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                cat.nome,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: selecionada
                                      ? cs.primary
                                      : cs.onSurface.withOpacity(0.6),
                                  fontWeight: selecionada
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    // Botão criar categoria
                    GestureDetector(
                      onTap: _abrirCriarCategoria,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cs.primary.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add,
                                size: 14, color: cs.onSurface.withOpacity(0.4)),
                            const SizedBox(width: 4),
                            Text(
                              'Criar categoria',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurface.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              _Label('Descrição (opcional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descricaoController,
                decoration:
                    _inputDecoration(context, 'Ex: Lanche da tarde').copyWith(
                  counterText: '',
                ),
                maxLines: 1,
                maxLength: 30,
              ),
              const SizedBox(height: 14),
              _Label('Data'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final data = await showDatePicker(
                    context: context,
                    initialDate: _dataSelecionada,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (data != null) setState(() => _dataSelecionada = data);
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.onSurface.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 16, color: cs.onSurface.withOpacity(0.4)),
                      const SizedBox(width: 8),
                      Text(formatarData(_dataSelecionada),
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _salvando ? null : _salvar,
                  child: _salvando
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.onPrimary),
                        )
                      : Text(
                          _editando ? 'Salvar alterações' : 'Salvar gasto',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Popup criar categoria inline ──────────────────────────────────────────────

class _PopupCriarCategoriaInline extends StatefulWidget {
  final int usuarioId;
  final Future<void> Function(Categoria) onSalvar;

  const _PopupCriarCategoriaInline(
      {required this.usuarioId, required this.onSalvar});

  @override
  State<_PopupCriarCategoriaInline> createState() =>
      _PopupCriarCategoriaInlineState();
}

class _PopupCriarCategoriaInlineState
    extends State<_PopupCriarCategoriaInline> {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Criar categoria',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text('Nome',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
            const SizedBox(height: 6),
            TextField(
              controller: _nomeController,
              autofocus: true,
              decoration: _inputDec(context, 'Ex: Pets'),
            ),
            const SizedBox(height: 14),
            Text('Ícone (escolha um emoji)',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
            const SizedBox(height: 6),
            EmojiPickerField(
              controller: _iconeController,
              hint: 'Ex: 🐶',
              inputDecoration: _inputDec,
            ),
            const SizedBox(height: 14),
            Text('Cor (opcional)',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
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
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: _salvando ? null : _salvar,
                child: _salvando
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.onPrimary),
                      )
                    : const Text('Salvar categoria',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Área de foto ──────────────────────────────────────────────────────────────

class _FotoArea extends StatelessWidget {
  final String? imagemPath;
  final VoidCallback onTap;

  const _FotoArea({required this.imagemPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.primary.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: imagemPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    exibirImagem(imagemPath!),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Trocar foto',
                            style:
                                TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      size: 32, color: cs.onSurface.withOpacity(0.3)),
                  const SizedBox(height: 6),
                  Text(
                    'Tirar foto / selecionar comprovante',
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurface.withOpacity(0.4)),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Label ─────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
}

// ── Máscara de moeda ──────────────────────────────────────────────────────────
// Mantém o campo sempre como "1.234.567,89"
// Máximo: 1.000.000.000.000,00 (13 dígitos inteiros + 2 decimais)

class _MoedaFormatter extends TextInputFormatter {
  static const int _maxIntDigits = 13; // 1 trilhão

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extrai apenas dígitos
    String digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Limita a 15 dígitos no total (13 inteiros + 2 decimais)
    if (digits.length > _maxIntDigits + 2) {
      digits = digits.substring(digits.length - (_maxIntDigits + 2));
    }

    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Garante pelo menos 3 dígitos para ter "0,00"
    digits = digits.padLeft(3, '0');

    // Separa decimais
    final decimais = digits.substring(digits.length - 2);
    var inteiros = digits.substring(0, digits.length - 2);

    // Remove zeros à esquerda nos inteiros (mas mantém pelo menos "0")
    inteiros = inteiros.replaceFirst(RegExp(r'^0+'), '');
    if (inteiros.isEmpty) inteiros = '0';

    // Insere pontos de milhar
    final buffer = StringBuffer();
    for (int i = 0; i < inteiros.length; i++) {
      if (i > 0 && (inteiros.length - i) % 3 == 0) buffer.write('.');
      buffer.write(inteiros[i]);
    }

    final resultado = '${buffer.toString()},${decimais}';
    return TextEditingValue(
      text: resultado,
      selection: TextSelection.collapsed(offset: resultado.length),
    );
  }
}
