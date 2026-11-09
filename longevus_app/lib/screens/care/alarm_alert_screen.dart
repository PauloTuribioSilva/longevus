import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class AlarmAlertScreen extends StatefulWidget {
  final String elderName;
  final int cuidadorId;
  final Map<String, dynamic>? prescricao;
  final Map<String, dynamic>? medicamento;

  const AlarmAlertScreen({
    super.key,
    required this.elderName,
    required this.cuidadorId,
    this.prescricao,
    this.medicamento,
  });

  @override
  State<AlarmAlertScreen> createState() => _AlarmAlertScreenState();
}

class _AlarmAlertScreenState extends State<AlarmAlertScreen> {
  bool _isSaving = false;

  String _formatHour(String? isoTimestamp) {
    if (isoTimestamp == null || isoTimestamp.isEmpty) return '08:00';
    final dt = DateTime.tryParse(isoTimestamp);
    if (dt == null) return '08:00';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _confirmDose(bool taken) async {
    setState(() => _isSaving = true);
    final supabase = Supabase.instance.client;

    try {
      if (widget.prescricao != null) {
        final nowIso = DateTime.now().toIso8601String();

        await supabase.from('administracao_prescricao').insert({
          'id_prescricao': widget.prescricao!['id_prescricao'],
          'id_cuidador': widget.cuidadorId,
          'administrado': taken,
          'horario_confirmacao': nowIso,
        });

        if (taken) {
          await supabase
              .from('prescricao')
              .update({'ultimo_uso_continuo': nowIso})
              .eq('id_prescricao', widget.prescricao!['id_prescricao']);
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            taken
                ? 'Dose confirmada! Toda a equipe foi notificada.'
                : 'Registrado como NÃO administrado.',
          ),
          backgroundColor: taken ? AppTheme.success : AppTheme.danger,
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
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final medName = widget.medicamento?['nome'] ?? 'Puran T4 (50mcg)';
    final medDesc =
        widget.medicamento?['descricao'] ?? 'Controle da tireoide (em jejum)';
    final fotoUrl = widget.medicamento?['foto_url'] as String?;
    final displayHour = _formatHour(widget.prescricao?['inicio_uso_continuo']);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Hora do remédio • ${widget.elderName}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayHour,
              style: const TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryStrong,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              medName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Para que serve: $medDesc',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Foto da caixa / comprimido'),
                    content: SizedBox(
                      height: 180,
                      child: (fotoUrl != null && fotoUrl.isNotEmpty)
                          ? Image.network(fotoUrl, fit: BoxFit.contain)
                          : const Center(
                              child: Icon(
                                Icons.medication,
                                size: 72,
                                color: AppTheme.primary,
                              ),
                            ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fechar'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: AppTheme.primaryStrong,
              ),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Ver FOTO do remédio'),
            ),
            const SizedBox(height: 28),
            if (_isSaving)
              const CircularProgressIndicator()
            else ...[
              ElevatedButton.icon(
                onPressed: () => _confirmDose(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  minimumSize: const Size(double.infinity, 60),
                ),
                icon: const Icon(Icons.check_circle, size: 28),
                label: const Text('JÁ TOMOU', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => _confirmDose(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  minimumSize: const Size(double.infinity, 60),
                ),
                icon: const Icon(Icons.cancel, size: 28),
                label: const Text('NÃO VAI TOMAR', style: TextStyle(fontSize: 18)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}