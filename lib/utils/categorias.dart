import 'package:flutter/material.dart';

class CategoriaInfo {
  final String nome;
  final IconData icone;
  final Color cor;
  final Color corFundo;

  const CategoriaInfo({
    required this.nome,
    required this.icone,
    required this.cor,
    required this.corFundo,
  });
}

const List<CategoriaInfo> categorias = [
  CategoriaInfo(
    nome: 'Alimentação',
    icone: Icons.restaurant_outlined,
    cor: Color(0xFF0F6E56),
    corFundo: Color(0xFFE1F5EE),
  ),
  CategoriaInfo(
    nome: 'Transporte',
    icone: Icons.directions_bus_outlined,
    cor: Color(0xFF185FA5),
    corFundo: Color(0xFFE6F1FB),
  ),
  CategoriaInfo(
    nome: 'Lazer',
    icone: Icons.sports_esports_outlined,
    cor: Color(0xFF534AB7),
    corFundo: Color(0xFFEEEDFE),
  ),
  CategoriaInfo(
    nome: 'Estudos',
    icone: Icons.menu_book_outlined,
    cor: Color(0xFF854F0B),
    corFundo: Color(0xFFFAEEDA),
  ),
  CategoriaInfo(
    nome: 'Saúde',
    icone: Icons.favorite_border,
    cor: Color(0xFFA32D2D),
    corFundo: Color(0xFFFCEBEB),
  ),
  CategoriaInfo(
    nome: 'Outros',
    icone: Icons.category_outlined,
    cor: Color(0xFF5F5E5A),
    corFundo: Color(0xFFF1EFE8),
  ),
];

CategoriaInfo categoriaInfo(String nome) {
  return categorias.firstWhere(
    (c) => c.nome == nome,
    orElse: () => categorias.last,
  );
}
