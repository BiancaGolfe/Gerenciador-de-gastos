import 'package:flutter/material.dart';
import '../models/gasto.dart';
import '../utils/categorias.dart';
import '../utils/formatters.dart';

class GastoCard extends StatelessWidget {
  final Gasto gasto;
  final VoidCallback? onTap;

  const GastoCard({super.key, required this.gasto, this.onTap});

  @override
  Widget build(BuildContext context) {
    final info = categoriaInfo(gasto.categoria);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: info.corFundo,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(info.icone, color: info.cor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gasto.descricao?.isNotEmpty == true
                        ? gasto.descricao!
                        : gasto.categoria,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    gasto.categoria,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              formatarMoeda(gasto.valor),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
