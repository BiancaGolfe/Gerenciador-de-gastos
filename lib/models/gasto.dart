class Gasto {
  final int? id;
  final int? usuarioId;
  final double valor;
  final String categoria;
  final String? descricao;
  final DateTime data;
  final String? imagemPath;

  Gasto({
    this.id,
    this.usuarioId,
    required this.valor,
    required this.categoria,
    this.descricao,
    required this.data,
    this.imagemPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'valor': valor,
      'categoria': categoria,
      'descricao': descricao,
      'data': data.toIso8601String(),
      'imagem_path': imagemPath,
    };
  }

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id'] as int?,
      usuarioId: map['usuario_id'] as int?,
      valor: (map['valor'] as num).toDouble(),
      categoria: map['categoria'] as String,
      descricao: map['descricao'] as String?,
      data: DateTime.parse(map['data'] as String),
      imagemPath: map['imagem_path'] as String?,
    );
  }

  Gasto copyWith({
    int? id,
    int? usuarioId,
    double? valor,
    String? categoria,
    String? descricao,
    DateTime? data,
    String? imagemPath,
  }) {
    return Gasto(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      valor: valor ?? this.valor,
      categoria: categoria ?? this.categoria,
      descricao: descricao ?? this.descricao,
      data: data ?? this.data,
      imagemPath: imagemPath ?? this.imagemPath,
    );
  }
}
