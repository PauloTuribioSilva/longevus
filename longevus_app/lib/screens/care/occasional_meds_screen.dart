import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/longevo_model.dart';

class OccasionalMedsScreen extends StatefulWidget {
  final LongevoVinculo vinculo;
  final int cuidadorId;

  const OccasionalMedsScreen({
    super.key,
    required this.vinculo,
    required this.cuidadorId,
  });

  @override
  State<OccasionalMedsScreen> createState() => _OccasionalMedsScreenState();
}

class _OccasionalMedsScreenState extends State<OccasionalMedsScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _occasionalFuture;

  @override
  void initState() {
    super.initState();
    _occasionalFuture = _fetchOccasionalMeds();
  }

  Future<List<Map<String, dynamic>>> _fetchOccasionalMeds() async {
    final response = await _supabase
        .from('prescricao')
        .select('*, medicamento(*), categoria_remedio_ocasional(*)')
        .eq('id_longevo', widget.vinculo.idLongevo)
        .eq('continuo', false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _registerOccasionalUse(Map<String, dynamic> presc) async {
    final med = presc['medicamento'] as Map<String, dynamic>;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Registrar ${med['nome']}?'),
        content: Text(
          'Orientação: ${med['descricao'] ?? 'Conforme prescrição médica.'}\n\nDeseja registrar que o medicamento foi dado agora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Sim, registrar uso'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('administracao_prescricao').insert({
        'id_prescricao': presc['id_prescricao'],
        'id_cuidador': widget.cuidadorId,
        'administrado': true,
        'horario_confirmacao': DateTime.now().toIso8601String(),
      });

      await _supabase.from('activity_log').insert({
        'id_longevo': widget.vinculo.idLongevo,
        'id_cuidador': widget.cuidadorId,
        'activity': 'Administrou remédio eventual: ${med['nome']}',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${med['nome']} registrado no histórico!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao registrar: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }  void _openAddOccasionalDialog() {
    final nameCtrl = TextEditingController();
    final symptomCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Novo remédio eventual',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryStrong,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: symptomCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Para o que serve? (ex: Dor de cabeça, Febre, Enjoo)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome do remédio (ex: Dipirona 500mg)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dosagem / Orientação (ex: 1 comprimido ou 30 gotas)',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (nameCtrl.text.trim().isEmpty ||
                                  symptomCtrl.text.trim().isEmpty) {
                                return;
                              }

                              setModalState(() => isSaving = true);

                              try {
                                final catRes = await _supabase
                                    .from('categoria_remedio_ocasional')
                                    .insert({'nome': symptomCtrl.text.trim()})
                                    .select('id_categoria_medicamento_ocasional')
                                    .single();

                                final medRes = await _supabase
                                    .from('medicamento')
                                    .insert({
                                      'nome': nameCtrl.text.trim(),
                                      'descricao': dosageCtrl.text.trim(),
                                    })
                                    .select('id_medicamento')
                                    .single();

                                await _supabase.from('prescricao').insert({
                                  'id_longevo': widget.vinculo.idLongevo,
                                  'id_medicamento': medRes['id_medicamento'],
                                  'id_categoria_medicamento_ocasional':
                                      catRes['id_categoria_medicamento_ocasional'],
                                  'continuo': false,
                                  'frequencia': 0,
                                });

                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);

                                if (!mounted) return;
                                setState(() {
                                  _occasionalFuture = _fetchOccasionalMeds();
                                });
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao salvar remédio: $e'),
                                    backgroundColor: AppTheme.danger,
                                  ),
                                );
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar remédio eventual'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.vinculo.apelidoLongevo,
              style: const TextStyle(fontSize: 14),
            ),
            const Text(
              'Remédios eventuais',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.vinculo.isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              onPressed: _openAddOccasionalDialog,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            )
          : null,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _occasionalFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
          }
          final meds = snapshot.data ?? [];
          if (meds.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum remédio eventual cadastrado.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: meds.length,
            itemBuilder: (context, index) {
              final presc = meds[index];
              final med = presc['medicamento'] as Map<String, dynamic>;
              final cat = presc['categoria_remedio_ocasional']
                  as Map<String, dynamic>?;
              final sintoma = cat?['nome'] ?? 'Uso eventual';

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: AppTheme.successSoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: AppTheme.success.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  title: Text(
                    '${med['nome']} • $sintoma',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryStrong,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      (med['descricao'] != null &&
                              med['descricao'].toString().isNotEmpty)
                          ? med['descricao']
                          : 'Toque para registrar administração',
                      style: const TextStyle(color: AppTheme.textDark),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.add_circle,
                    color: AppTheme.success,
                    size: 30,
                  ),
                  onTap: () => _registerOccasionalUse(presc),
                ),
              );
            },
          );
        },
      ),
    );
  }
}