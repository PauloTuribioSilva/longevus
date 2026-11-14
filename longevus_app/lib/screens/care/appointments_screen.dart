import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../features/admin/edit_appointment_screen.dart';
import '../../models/longevo_model.dart';

class AppointmentsScreen extends StatefulWidget {
  final LongevoVinculo vinculo;
  final int cuidadorId;

  const AppointmentsScreen({
    super.key,
    required this.vinculo,
    required this.cuidadorId,
  });

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List> _consultasFuture;

  @override
  void initState() {
    super.initState();
    _consultasFuture = _fetchConsultas();
  }

  Future<List> _fetchConsultas() async {
    final response = await _supabase
        .from('consulta')
        .select('*')
        .eq('id_longevo', widget.vinculo.idLongevo)
        .order('data_horario', ascending: true);

    return List.from(response);
  }

  Future<void> _abrirFormularioConsulta([Map<String, dynamic>? consulta]) async {
    final atualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditAppointmentScreen(
          idLongevo: widget.vinculo.idLongevo,
          consulta: consulta,
        ),
      ),
    );

    if (atualizado == true && mounted) {
      setState(() {
        _consultasFuture = _fetchConsultas();
      });
    }
  }

  Future<void> _alternarRealizada(Map<String, dynamic> consulta) async {
    final bool novoStatus = !(consulta['realizada'] as bool? ?? false);
    await _supabase
        .from('consulta')
        .update({'realizada': novoStatus})
        .eq('id_consulta', consulta['id_consulta']);

    if (mounted) {
      setState(() {
        _consultasFuture = _fetchConsultas();
      });
    }
  }

  String _formatarDataHora(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${dt.year} às $hh:$min';
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
              'Consultas e Exames',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.vinculo.isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              onPressed: () => _abrirFormularioConsulta(),
              icon: const Icon(Icons.add),
              label: const Text('Nova Consulta'),
            )
          : null,
      body: FutureBuilder<List>(
        future: _consultasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
          }

          final consultas = snapshot.data ?? [];
          if (consultas.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma consulta agendada.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: consultas.length,
            itemBuilder: (context, index) {
              final item = consultas[index];
              final bool realizada = item['realizada'] as bool? ?? false;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 14),
                color: realizada ? Colors.grey.shade100 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: realizada ? Colors.grey.shade300 : AppTheme.line,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: realizada
                                  ? AppTheme.successSoft
                                  : AppTheme.primarySoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatarDataHora(item['data_horario']),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: realizada
                                    ? AppTheme.success
                                    : AppTheme.primaryStrong,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (widget.vinculo.isAdmin)
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppTheme.primary,
                              ),
                              tooltip: 'Editar consulta',
                              onPressed: () => _abrirFormularioConsulta(item),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['especialidade'] ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          decoration:
                              realizada ? TextDecoration.lineThrough : null,
                          color: AppTheme.primaryStrong,
                        ),
                      ),
                      if (item['nome_medico'] != null) ...[
                        const SizedBox(height: 4),
                        Text('Médico(a): ${item['nome_medico']}'),
                      ],
                      if (item['local_consulta'] != null) ...[
                        const SizedBox(height: 2),
                        Text('Local: ${item['local_consulta']}'),
                      ],
                      if (item['observacoes'] != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Obs: ${item['observacoes']}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                      const Divider(height: 20),
                      InkWell(
                        onTap: () => _alternarRealizada(item),
                        child: Row(
                          children: [
                            Icon(
                              realizada
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: realizada
                                  ? AppTheme.success
                                  : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              realizada
                                  ? 'Consulta realizada'
                                  : 'Marcar como realizada',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: realizada
                                    ? AppTheme.success
                                    : AppTheme.textDark,
                              ),
                            ),
                          ],
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