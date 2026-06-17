class Usuario {
  final int? id;
  final String nome;
  final String email;
  final String senha;

  const Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.senha,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'email': email,
        'senha': senha,
      };

  factory Usuario.fromMap(Map<String, dynamic> map) => Usuario(
        id: map['id'] as int?,
        nome: map['nome'] as String,
        email: map['email'] as String,
        senha: map['senha'] as String,
      );
}
