class Categoria {
  final int? id;
  final String nome;
  final String icone; // emoji ou texto
  final bool fixa; // categorias padrão não podem ser excluídas

  const Categoria({
    this.id,
    required this.nome,
    required this.icone,
    this.fixa = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'icone': icone,
        'fixa': fixa ? 1 : 0,
      };

  factory Categoria.fromMap(Map<String, dynamic> map) => Categoria(
        id: map['id'] as int?,
        nome: map['nome'] as String,
        icone: map['icone'] as String,
        fixa: (map['fixa'] as int) == 1,
      );

  Categoria copyWith({int? id, String? nome, String? icone, bool? fixa}) =>
      Categoria(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        icone: icone ?? this.icone,
        fixa: fixa ?? this.fixa,
      );
}
