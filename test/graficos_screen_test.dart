import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:controle_gastos/models/categoria.dart';
import 'package:controle_gastos/screens/graficos_screen.dart';

void main() {
  test('usa a cor personalizada da categoria no gráfico', () {
    final categorias = [
      const Categoria(nome: 'Pets', icone: '🐶', cor: 'FF0000'),
    ];

    final cor = resolverCorCategoria(
      nomeCategoria: 'Pets',
      categorias: categorias,
    );

    expect(cor, const Color(0xFFFF0000));
  });
}
