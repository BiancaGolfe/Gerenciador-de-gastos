import 'package:flutter/material.dart';

class Categoria {
  final int? id;
  final int? usuarioId;
  final String nome;
  final String icone; 
  final bool fixa; 
  final String? cor; 
  final String? corFundo; 

  const Categoria({
    this.id,
    this.usuarioId,
    required this.nome,
    required this.icone,
    this.fixa = false,
    this.cor,
    this.corFundo,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'usuario_id': usuarioId,
        'nome': nome,
        'icone': icone,
        'fixa': fixa ? 1 : 0,
        'cor': cor,
        'cor_fundo': corFundo,
      };

  factory Categoria.fromMap(Map<String, dynamic> map) => Categoria(
        id: map['id'] as int?,
        usuarioId: map['usuario_id'] as int?,
        nome: map['nome'] as String,
        icone: map['icone'] as String,
        fixa: (map['fixa'] as int) == 1,
        cor: map['cor'] as String?,
        corFundo: map['cor_fundo'] as String?,
      );

  Categoria copyWith({
    int? id,
    int? usuarioId,
    String? nome,
    String? icone,
    bool? fixa,
    String? cor,
    String? corFundo,
  }) =>
      Categoria(
        id: id ?? this.id,
        usuarioId: usuarioId ?? this.usuarioId,
        nome: nome ?? this.nome,
        icone: icone ?? this.icone,
        fixa: fixa ?? this.fixa,
        cor: cor ?? this.cor,
        corFundo: corFundo ?? this.corFundo,
      );
}
