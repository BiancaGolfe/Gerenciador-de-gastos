class Categoria {
  final int? id;
  final int? usuarioId;
  final String nome;
  final String icone; // emoji ou texto
  final bool fixa; // categorias padrão não podem ser excluídas

  const Categoria({
    this.id,
    this.usuarioId,
    required this.nome,
    required this.icone,
    this.fixa = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'usuario_id': usuarioId,
        'nome': nome,
        'icone': icone,
        'fixa': fixa ? 1 : 0,
      };

  factory Categoria.fromMap(Map<String, dynamic> map) => Categoria(
        id: map['id'] as int?,
        usuarioId: map['usuario_id'] as int?,
        nome: map['nome'] as String,
        icone: map['icone'] as String,
        fixa: (map['fixa'] as int) == 1,
      );

  Categoria copyWith({int? id, int? usuarioId, String? nome, String? icone, bool? fixa}) =>
      Categoria(
        id: id ?? this.id,
        usuarioId: usuarioId ?? this.usuarioId,
        nome: nome ?? this.nome,
        icone: icone ?? this.icone,
        fixa: fixa ?? this.fixa,
      );
}
