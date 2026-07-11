import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/gasto.dart';
import '../utils/categorias.dart';
import '../utils/formatters.dart';
import '../utils/image_helper.dart';
import '../utils/notifiers.dart';
import 'cadastro_screen.dart';

class DetalheScreen extends StatelessWidget {
  final Gasto gasto;

  const DetalheScreen({super.key, required this.gasto});

  @override
  Widget build(BuildContext context) {
    final info = categoriaInfo(gasto.categoria);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Detalhe do gasto'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _FotoComprovante(imagemPath: gasto.imagemPath),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.onSurface.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _LinhaDetalhe(
                    label: 'Valor',
                    valor: formatarMoeda(gasto.valor),
                    valorStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  const _Divisor(),
                  _LinhaDetalhe(
                    label: 'Categoria',
                    custom: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: info.cor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(gasto.categoria,
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const _Divisor(),
                  _LinhaDetalheDescricao(
                    label: 'Descrição',
                    valor: gasto.descricao?.isNotEmpty == true ? gasto.descricao! : '—',
                  ),
                  const _Divisor(),
                  _LinhaDetalhe(
                    label: 'Data',
                    valor: formatarData(gasto.data),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CadastroScreen(
                            gastoParaEditar: gasto,
                            usuarioId: gasto.usuarioId ?? 0,
                          ),
                        ),
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFA32D2D)),
                    label: const Text('Excluir',
                        style: TextStyle(color: Color(0xFFA32D2D))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFF09595)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _confirmarExclusao(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir gasto'),
        content: const Text('Tem certeza que deseja excluir este gasto?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Color(0xFFA32D2D))),
          ),
        ],
      ),
    );

    if (confirmar == true && gasto.id != null) {
      await DatabaseHelper.instance.excluir(gasto.id!);
      gastosNotifier.value++;
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _FotoComprovante extends StatelessWidget {
  final String? imagemPath;

  const _FotoComprovante({this.imagemPath});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.12)),
      ),
      child: imagemPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: exibirImagem(imagemPath!),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_outlined, size: 40, color: cs.onSurface.withOpacity(0.3)),
                const SizedBox(height: 6),
                Text('Sem comprovante',
                    style: TextStyle(color: cs.onSurface.withOpacity(0.3), fontSize: 13)),
              ],
            ),
    );
  }
}

class _LinhaDetalhe extends StatelessWidget {
  final String label;
  final String? valor;
  final TextStyle? valorStyle;
  final Widget? custom;
  final bool isLast;

  const _LinhaDetalhe({
    required this.label,
    this.valor,
    this.valorStyle,
    this.custom,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.5))),
          custom ??
              Text(
                valor ?? '—',
                style: valorStyle ??
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
        ],
      ),
    );
  }
}

class _Divisor extends StatelessWidget {
  const _Divisor();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1));
}


class _LinhaDetalheDescricao extends StatelessWidget {
  final String label;
  final String valor;

  const _LinhaDetalheDescricao({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.5))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
