class Cuidador {
  final int? idCuidador;
  final String nomeCompleto;
  final String abreviatura;
  final String cpf;
  final String email;
  final String telefone;

  Cuidador({
    this.idCuidador,
    required this.nomeCompleto,
    required this.abreviatura,
    required this.cpf,
    required this.email,
    required this.telefone,
  });

  factory Cuidador.fromJson(Map<String, dynamic> json) => Cuidador(
        idCuidador: json['id_cuidador'],
        nomeCompleto: json['nome_completo'] ?? '',
        abreviatura: json['abreviatura'] ?? '',
        cpf: json['cpf'] ?? '',
        email: json['email'] ?? '',
        telefone: json['telefone'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        if (idCuidador != null) 'id_cuidador': idCuidador,
        'nome_completo': nomeCompleto,
        'abreviatura': abreviatura,
        'cpf': cpf,
        'email': email,
        'telefone': telefone,
      };
}