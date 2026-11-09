import 'dart:core';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/longevo_model.dart';
import 'alarm_alert_screen.dart';

class DailyMedsScreen extends StatefulWidget {
  final LongevoVinculo vinculo;
  final int cuidadorId;

  const DailyMedsScreen({
    super.key,
    required this.vinculo,
    required this.cuidadorId,
  });

  @override
  State<DailyMedsScreen> createState() => _DailyMedsScreenState();
}

class _DailyMedsScreenState extends State<DailyMedsScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List> _medsFuture;

  @override
  void initState() {
    super.initState();
    _medsFuture = _fetchDailyMeds();
  }

  Future<List<Map<String, dynamic>>> _fetchDailyMeds() async {
  final response = await _supabase
      .from('prescricao')
      .select('*, medicamento(*)')
      .eq('id_longevo', widget.vinculo.idLongevo)
      .eq('continuo', true)
      .order('inicio_uso_continuo', ascending: true);

  return List<Map<String, dynamic>>.from(response);
}
  String _formatHour(String? isoTimestamp) {
    if (isoTimestamp == null || isoTimestamp.isEmpty) return '--:--';
    final dt = DateTime.tryParse(isoTimestamp);
    if (dt == null) return '--:--';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void _openAddMedicationDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final bulaCtrl = TextEditingController();
    final freqCtrl = TextEditingController(text: '24');
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Novo remédio do dia a dia',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryStrong,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome e dosagem (ex: Puran T4 50mcg)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Para que serve? (ex: Tireoide - em jejum)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: ctx,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setModalState(() => selectedTime = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Horário inicial',
                              ),
                              child: Text(
                                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: freqCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Repetir a cada (horas)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bulaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Link da bula ou observação (opcional)',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;

                        final medRes = await _supabase
                            .from('medicamento')
                            .insert({
                              'nome': nameCtrl.text.trim(),
                              'descricao': descCtrl.text.trim(),
                              'bula': bulaCtrl.text.trim(),
                            })
                            .select('id_medicamento')
                            .single();

                        final now = DateTime.now();
                        final startDateTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );

                        await _supabase.from('prescricao').insert({
                          'id_longevo': widget.vinculo.idLongevo,
                          'id_medicamento': medRes['id_medicamento'],
                          'continuo': true,
                          'inicio_uso_continuo': startDateTime.toIso8601String(),
                          'frequencia': int.tryParse(freqCtrl.text.trim()) ?? 24,
                        });

                        if (!mounted) return;
                        Navigator.pop(ctx);
                        setState(() {
                          _medsFuture = _fetchDailyMeds();
                        });
                      },
                      child: const Text('Salvar medicamento'),
                    ),
                  ],
                ),
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
              'Remédios do dia a dia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.vinculo.isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              onPressed: _openAddMedicationDialog,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            )
          : null,
      body: FutureBuilder<List>(
        future: _medsFuture,
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
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhum remédio contínuo cadastrado ainda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: meds.length,
            itemBuilder: (context, index) {
              final presc = meds[index];
              final med = presc['medicamento'] as Map<String, dynamic>;
              final hora = _formatHour(presc['inicio_uso_continuo']);
              final ultimoUso = presc['ultimo_uso_continuo'] != null
                  ? _formatHour(presc['ultimo_uso_continuo'])
                  : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlarmAlertScreen(
                          elderName: widget.vinculo.apelidoLongevo,
                          cuidadorId: widget.cuidadorId,
                          prescricao: presc,
                          medicamento: med,
                        ),
                      ),
                    );
                    setState(() {
                      _medsFuture = _fetchDailyMeds();
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: AppTheme.secondarySoft,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.secondary),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              hora,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryStrong,
                              ),
                            ),
                            Text(
                              '${presc['frequencia']}h/${presc['frequencia']}h',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 84),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${med['nome']} - ${med['descricao'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryStrong,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ultimoUso != null
                                    ? 'Última confirmação hoje às $ultimoUso'
                                    : 'Toque para confirmar dose (Sim / Não)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: ultimoUso != null
                                      ? AppTheme.success
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}