import 'dart:core';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../features/admin/edit_med_screen.dart';
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

  Future<List> _fetchDailyMeds() async {
    final response = await _supabase
        .from('prescricao')
        .select('*, medicamento(*)')
        .eq('id_longevo', widget.vinculo.idLongevo)
        .eq('continuo', true)
        .order('inicio_uso_continuo', ascending: true);

    return List.from(response);
  }

  String _formatHour(String? isoTimestamp) {
    if (isoTimestamp == null || isoTimestamp.isEmpty) return '--:--';
    final dt = DateTime.tryParse(isoTimestamp);
    if (dt == null) return '--:--';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
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
        _medsFuture = _fetchDailyMeds();
      });
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
              onPressed: () => _abrirTelaMedicamento(),
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
              final String? fotoUrl = med['foto_url'] as String?;

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
                    if (mounted) {
                      setState(() {
                        _medsFuture = _fetchDailyMeds();
                      });
                    }
                  },
                  child: Row(
                    children: [
                      // Bloco lateral com horário e frequência
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

                      // Card principal com dados do medicamento + botão editar
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 84),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.line),
                          ),
                          child: Row(
                            children: [
                              if (fotoUrl != null && fotoUrl.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    fotoUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${med['nome']} ${med['descricao'] ?? ''}',
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
                              if (widget.vinculo.isAdmin)
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: AppTheme.primary,
                                  ),
                                  tooltip: 'Editar medicamento',
                                  onPressed: () => _abrirTelaMedicamento(presc),
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