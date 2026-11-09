class LongevoVinculo {
  final int idLongevo;
  final String nomeCompleto;
  final int? idade;
  final String cpf;
  final String apelidoLongevo; // Vem de longevo_cuidador
  final String relacionamento; // Ex: Filha, Neto, Cuidador
  final bool isAdmin;          // Define se vê opções de edição ou apenas cuidado

  LongevoVinculo({
    required this.idLongevo,
    required this.nomeCompleto,
    this.idade,
    required this.cpf,
    required this.apelidoLongevo,
    required this.relacionamento,
    required this.isAdmin,
  });
}