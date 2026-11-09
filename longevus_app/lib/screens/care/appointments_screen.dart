import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
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
  late Future<List<dynamic>> _appointmentsFuture;

  final List<String> _monthsShort = const [
    'JAN',
    'FEV',
    'MAR',
    'ABR',
    'MAI',
    'JUN',
    'JUL',
    'AGO',
    'SET',
    'OUT',
    'NOV',
    'DEZ',
  ];

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = _fetchAppointments();
  }

  Future<List<dynamic>> _fetchAppointments() async {
    final response = await _supabase
        .from('consulta')
        .select('*, cuidador:id_cuidador_responsavel(id_cuidador, nome_completo, abreviatura)')
        .eq('id_longevo', widget.vinculo.idLongevo)
        .order('data_consulta', ascending: true)
        .order('horario', ascending: true);

    return response as List<dynamic>;
  }

  Future<List<dynamic>> _fetchTeamCaregivers() async {
    final response = await _supabase
        .from('longevo_cuidador')
        .select('id_cuidador, cuidador(id_cuidador, nome_completo)')
        .eq('id_longevo', widget.vinculo.idLongevo);

    return response as List<dynamic>;
  }

  void _openAddAppointmentDialog() async {
    final caregivers = await _fetchTeamCaregivers();
    if (!mounted) return;

    final doctorCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    int? selectedCaregiverId = widget.cuidadorId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final dateFormatted =
                '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
            final timeFormatted =
                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

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
                      'Agendar consulta',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryStrong,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: doctorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Médico / Especialidade (ex: Cardiologista - Dr. Silva)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 730)),
                              );
                              if (picked != null) {
                                setModalState(() => selectedDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Data'),
                              child: Text(
                                dateFormatted,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                              decoration: const InputDecoration(labelText: 'Horário'),
                              child: Text(
                                timeFormatted,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Endereço / Clínica',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedCaregiverId,
                      decoration: const InputDecoration(
                        labelText: 'Quem vai levar?',
                      ),
                      items: caregivers.map((row) {
                        final c = row['cuidador'] as Map<String, dynamic>;
                        return DropdownMenuItem<int>(
                          value: c['id_cuidador'] as int,
                          child: Text(c['nome_completo'] ?? 'Cuidador'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() => selectedCaregiverId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Observações (ex: Levar exames anteriores)',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (doctorCtrl.text.trim().isEmpty) return;

                        final dateSql =
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                        final timeSql = '$timeFormatted:00';

                        await _supabase.from('consulta').insert({
                          'id_longevo': widget.vinculo.idLongevo,
                          'id_cuidador_responsavel': selectedCaregiverId,
                          'data_consulta': dateSql,
                          'horario': timeSql,
                          'medico_especialidade': doctorCtrl.text.trim(),
                          'endereco': addressCtrl.text.trim(),
                          'observacoes': notesCtrl.text.trim(),
                        });

                        await _supabase.from('activity_log').insert({
                          'id_longevo': widget.vinculo.idLongevo,
                          'id_cuidador': widget.cuidadorId,
                          'activity': 'Agendou consulta: ${doctorCtrl.text.trim()} ($dateFormatted)',
                        });

                        if (!mounted) return;
                        Navigator.pop(ctx);
                        setState(() {
                          _appointmentsFuture = _fetchAppointments();
                        });
                      },
                      child: const Text('Salvar consulta'),
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

  Future<void> _deleteAppointment(int idConsulta) async {
    await _supabase.from('consulta').delete().eq('id_consulta', idConsulta);
    setState(() {
      _appointmentsFuture = _fetchAppointments();
    });
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
              'Agenda de consultas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.vinculo.isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              onPressed: _openAddAppointmentDialog,
              icon: const Icon(Icons.add),
              label: const Text('Agendar consulta'),
            )
          : null,
      body: FutureBuilder<List<dynamic>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhuma consulta agendada no momento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index] as Map<String, dynamic>;
              final date = DateTime.tryParse(item['data_consulta'] ?? '') ?? DateTime.now();
              final timeStr = (item['horario'] ?? '00:00:00').toString().substring(0, 5);
              final cuidador = item['cuidador'] as Map<String, dynamic>?;
              final responsavel = cuidador?['nome_completo'] ?? 'A definir';

              // Layout fiel ao wireframe (Pág. 7): Data à esquerda + Detalhes à direita
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bloco da Data (Dia + Mês)
                    Container(
                      width: 76,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.secondarySoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.secondary),
                      ),
                      child: Column(
                        children: [
                          Text(
                            date.day.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryStrong,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _monthsShort[date.month - 1],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Cartão com Hora, Médico, Endereço e Quem vai levar
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primarySoft,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    'Horário: $timeStr',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                                if (widget.vinculo.isAdmin)
                                  InkWell(
                                    onTap: () => _deleteAppointment(item['id_consulta']),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: AppTheme.danger,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['medico_especialidade'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryStrong,
                              ),
                            ),
                            if ((item['endereco'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 15, color: AppTheme.textMuted),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item['endereco'],
                                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.successSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.directions_car_filled, size: 16, color: AppTheme.success),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Quem vai levar: $responsavel',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if ((item['observacoes'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Obs: ${item['observacoes']}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}