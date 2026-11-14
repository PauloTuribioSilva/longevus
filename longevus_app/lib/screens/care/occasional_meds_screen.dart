import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../features/admin/edit_med_screen.dart';
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
  late Future<List> _occasionalFuture;

  @override
  void initState() {
    super.initState();
    _occasionalFuture = _fetchOccasionalMeds();
  }

  Future<List> _fetchOccasionalMeds() async {
    final response = await _supabase
        .from('prescricao')
        .select('*, medicamento(*), categoria_remedio_ocasional(*)')
        .eq('id_longevo', widget.vinculo.idLongevo)
        .eq('continuo', false);

    return List.from(response);
  }

  Future<void> _abrirTelaMedicamento([Map<String, dynamic>? prescricao]) async {
    final atualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditMedScreen(
          idLongevo: widget.vinculo.idLongevo,
          prescricao: prescricao,
        ),
      ),
    );

    if (atualizado == true && mounted) {
      setState(() {
        _occasionalFuture = _fetchOccasionalMeds();
      });
    }
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
              onPressed: () => _abrirTelaMedicamento(),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            )
          : null,
      body: FutureBuilder<List>(
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
              final String? fotoUrl = med['foto_url'] as String?;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: AppTheme.successSoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: AppTheme.success.withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  leading: (fotoUrl != null && fotoUrl.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            fotoUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.medication_liquid_rounded,
                              color: AppTheme.success,
                              size: 32,
                            ),
                          ),
                        )
                      : null,
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.vinculo.isAdmin)
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppTheme.primary,
                          ),
                          tooltip: 'Editar medicamento',
                          onPressed: () => _abrirTelaMedicamento(presc),
                        ),
                      const Icon(
                        Icons.add_circle,
                        color: AppTheme.success,
                        size: 30,
                      ),
                    ],
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