import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class EditAppointmentScreen extends StatefulWidget {
  final int idLongevo;
  /// Se vier preenchido, abre em modo Edição; se null, abre em modo Criação.
  final Map<String, dynamic>? consulta;

  const EditAppointmentScreen({
    super.key,
    required this.idLongevo,
    this.consulta,
  });

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _especialidadeCtrl;
  late final TextEditingController _medicoCtrl;
  late final TextEditingController _localCtrl;
  late final TextEditingController _observacoesCtrl;

  late DateTime _dataSelecionada;
  late TimeOfDay _horaSelecionada;
  bool _realizada = false;
  bool _isSaving = false;

  bool get _isEditing => widget.consulta != null;

  @override
  void initState() {
    super.initState();
    _especialidadeCtrl = TextEditingController(
      text: widget.consulta?['especialidade'] ?? '',
    );
    _medicoCtrl = TextEditingController(
      text: widget.consulta?['nome_medico'] ?? '',
    );
    _localCtrl = TextEditingController(
      text: widget.consulta?['local_consulta'] ?? '',
    );
    _observacoesCtrl = TextEditingController(
      text: widget.consulta?['observacoes'] ?? '',
    );

    if (_isEditing && widget.consulta!['data_horario'] != null) {
      final dt = DateTime.parse(widget.consulta!['data_horario']);
      _dataSelecionada = DateTime(dt.year, dt.month, dt.day);
      _horaSelecionada = TimeOfDay(hour: dt.hour, minute: dt.minute);
      _realizada = widget.consulta!['realizada'] as bool? ?? false;
    } else {
      final amanha = DateTime.now().add(const Duration(days: 1));
      _dataSelecionada = DateTime(amanha.year, amanha.month, amanha.day);
      _horaSelecionada = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _especialidadeCtrl.dispose();
    _medicoCtrl.dispose();
    _localCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _dataSelecionada = picked);
    }
  }

  Future<void> _selecionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaSelecionada,
    );
    if (picked != null) {
      setState(() => _horaSelecionada = picked);
    }
  }

  String _formatarData(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    return '$dd/$mm/${dt.year}';
  }

  String _formatarHora(TimeOfDay tod) {
    final hh = tod.hour.toString().padLeft(2, '0');
    final mm = tod.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _salvarConsulta() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dataHorario = DateTime(
        _dataSelecionada.year,
        _dataSelecionada.month,
        _dataSelecionada.day,
        _horaSelecionada.hour,
        _horaSelecionada.minute,
      );

      final dados = {
        'id_longevo': widget.idLongevo,
        'especialidade': _especialidadeCtrl.text.trim(),
        'nome_medico': _medicoCtrl.text.trim().isEmpty
            ? null
            : _medicoCtrl.text.trim(),
        'local_consulta': _localCtrl.text.trim().isEmpty
            ? null
            : _localCtrl.text.trim(),
        'data_horario': dataHorario.toIso8601String(),
        'observacoes': _observacoesCtrl.text.trim().isEmpty
            ? null
            : _observacoesCtrl.text.trim(),
        'realizada': _realizada,
      };

      if (_isEditing) {
        final int idConsulta = widget.consulta!['id_consulta'] as int;
        await _supabase
            .from('consulta')
            .update(dados)
            .eq('id_consulta', idConsulta);
      } else {
        await _supabase.from('consulta').insert(dados);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Consulta atualizada com sucesso!'
                : 'Consulta agendada com sucesso!',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar consulta: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _excluirConsulta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Consulta'),
        content: const Text('Deseja realmente apagar este agendamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isSaving = true);
    try {
      final int idConsulta = widget.consulta!['id_consulta'] as int;
      await _supabase
          .from('consulta')
          .delete()
          .eq('id_consulta', idConsulta);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consulta removida.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Consulta' : 'Nova Consulta'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
              tooltip: 'Excluir consulta',
              onPressed: _isSaving ? null : _excluirConsulta,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _especialidadeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Especialidade *',
                      hintText: 'Ex: Cardiologista, Geriatra, Exame de Sangue',
                      prefixIcon: Icon(Icons.medical_services_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe a especialidade ou tipo de atendimento.'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selecionarData,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Data *',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(
                              _formatarData(_dataSelecionada),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _selecionarHora,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Horário *',
                              prefixIcon: Icon(Icons.access_time_outlined),
                            ),
                            child: Text(
                              _formatarHora(_horaSelecionada),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _medicoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Médico (opcional)',
                      hintText: 'Ex: Dr. Roberto Almeida',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _localCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Clínica / Endereço (opcional)',
                      hintText: 'Ex: Clínica Santa Casa - Sala 204',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _observacoesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Preparo / Observações (opcional)',
                      hintText: 'Ex: Jejum de 8h, levar exames anteriores e RG',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isEditing)
                    SwitchListTile(
                      title: const Text(
                        'Consulta já realizada',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      value: _realizada,
                      activeThumbColor: AppTheme.success,
                      onChanged: (val) => setState(() => _realizada = val),
                    ),

                  const SizedBox(height: 28),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _salvarConsulta,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _isSaving
                            ? 'Salvando...'
                            : (_isEditing
                                ? 'Salvar Alterações'
                                : 'Agendar Consulta'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}