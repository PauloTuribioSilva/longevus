import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/photo_picker_avatar.dart';

class EditMedScreen extends StatefulWidget {
  final int idLongevo;
  final Map<String, dynamic>? prescricao;

  const EditMedScreen({
    super.key,
    required this.idLongevo,
    this.prescricao,
  });

  @override
  State<EditMedScreen> createState() => _EditMedScreenState();
}

class _EditMedScreenState extends State<EditMedScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _descricaoCtrl;
  late final TextEditingController _bulaCtrl;
  late final TextEditingController _frequenciaCtrl;

  bool _isContinuo = true;
  int? _idCategoriaSelecionada;
  List _categorias = [];
  bool _carregandoCategorias = true;

  XFile? _novaFoto;
  Uint8List? _novaFotoBytes;
  String? _fotoAtualUrl;
  bool _isSaving = false;

  bool get _isEditing => widget.prescricao != null;

  @override
  void initState() {
    super.initState();
    final med = widget.prescricao?['medicamento'] as Map<String, dynamic>?;

    _nomeCtrl = TextEditingController(text: med?['nome'] ?? '');
    _descricaoCtrl = TextEditingController(text: med?['descricao'] ?? '');
    _bulaCtrl = TextEditingController(text: med?['bula'] ?? '');
    _fotoAtualUrl = med?['foto_url'] as String?;

    if (_isEditing) {
      _isContinuo = widget.prescricao!['continuo'] as bool? ?? true;
      _idCategoriaSelecionada =
          widget.prescricao!['id_categoria_medicamento_ocasional'] as int?;
      final freq = widget.prescricao!['frequencia'] ?? 8;
      _frequenciaCtrl = TextEditingController(text: freq.toString());
    } else {
      _frequenciaCtrl = TextEditingController(text: '8');
    }

    _carregarCategorias();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _bulaCtrl.dispose();
    _frequenciaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarCategorias() async {
    try {
      final data = await _supabase
          .from('categoria_remedio_ocasional')
          .select('id_categoria_medicamento_ocasional, nome')
          .order('nome');

      if (!mounted) return;
      final lista = List<Map<String, dynamic>>.from(data);

      setState(() {
        _categorias = lista;
        if (_idCategoriaSelecionada == null && _categorias.isNotEmpty) {
          _idCategoriaSelecionada =
              _categorias.first['id_categoria_medicamento_ocasional'] as int;
        }
        _carregandoCategorias = false;
      });
    } catch (e) {
      if (mounted) setState(() => _carregandoCategorias = false);
    }
  }

  Future<void> _escolherFoto() async {
    final arquivo = await StorageService.selecionarImagem();
    if (arquivo != null) {
      final bytes = await arquivo.readAsBytes();
      setState(() {
        _novaFoto = arquivo;
        _novaFotoBytes = bytes;
      });
    }
  }

  Future<void> _salvarMedicamento() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? fotoUrl = _fotoAtualUrl;

    if (_novaFoto != null) {
     final uploadedUrl = await StorageService.uploadImagem(
      arquivo: _novaFoto!,
      pasta: 'remedios', // subpasta dentro de longevus_arquivos
      identificador: 'med_${widget.idLongevo}_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (uploadedUrl != null) {
      fotoUrl = uploadedUrl;
  }
}

      final dadosMedicamento = {
        'nome': _nomeCtrl.text.trim(),
        'descricao': _descricaoCtrl.text.trim(),
        'bula': _bulaCtrl.text.trim().isEmpty ? null : _bulaCtrl.text.trim(),
        'foto_url': fotoUrl,
      };

      final int frequenciaHoras =
          _isContinuo ? (int.tryParse(_frequenciaCtrl.text.trim()) ?? 8) : 0;

      if (_isEditing) {
        final int idPrescricao = widget.prescricao!['id_prescricao'] as int;
        final int idMedicamento = widget.prescricao!['id_medicamento'] as int;

        await _supabase
            .from('medicamento')
            .update(dadosMedicamento)
            .eq('id_medicamento', idMedicamento);

        await _supabase.from('prescricao').update({
          'continuo': _isContinuo,
          'id_categoria_medicamento_ocasional':
              _isContinuo ? null : _idCategoriaSelecionada,
          'frequencia': frequenciaHoras,
          'inicio_uso_continuo': _isContinuo
              ? (widget.prescricao!['inicio_uso_continuo'] ??
                  DateTime.now().toIso8601String())
              : null,
        }).eq('id_prescricao', idPrescricao);
      } else {
        final novoMed = await _supabase
            .from('medicamento')
            .insert(dadosMedicamento)
            .select('id_medicamento')
            .single();

        final int novoIdMedicamento = novoMed['id_medicamento'] as int;

        await _supabase.from('prescricao').insert({
          'id_longevo': widget.idLongevo,
          'id_medicamento': novoIdMedicamento,
          'continuo': _isContinuo,
          'id_categoria_medicamento_ocasional':
              _isContinuo ? null : _idCategoriaSelecionada,
          'frequencia': frequenciaHoras,
          'inicio_uso_continuo':
              _isContinuo ? DateTime.now().toIso8601String() : null,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Medicamento atualizado com sucesso!'
                : 'Medicamento cadastrado com sucesso!',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar medicamento: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _excluirPrescricao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Medicamento'),
        content: const Text(
          'Deseja realmente excluir este medicamento da lista?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Excluir Definitivamente'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isSaving = true);
    try {
      final int idPrescricao = widget.prescricao!['id_prescricao'] as int;
      await _supabase
          .from('prescricao')
          .delete()
          .eq('id_prescricao', idPrescricao);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicamento excluído com sucesso.')),
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
        title: Text(_isEditing ? 'Editar Medicamento' : 'Novo Medicamento'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
              tooltip: 'Excluir medicamento',
              onPressed: _isSaving ? null : _excluirPrescricao,
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
                  PhotoPickerAvatar(
                    currentPhotoUrl: _fotoAtualUrl,
                    selectedImageBytes: _novaFotoBytes,
                    onTapPick: _escolherFoto,
                    fallbackIcon: Icons.medication_rounded,
                    isCircle: false,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Foto da caixa ou comprimido (opcional)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _nomeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome e Dosagem *',
                      hintText: 'Ex: Vonau 30 g',
                      prefixIcon: Icon(Icons.medication_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o nome do medicamento.'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descricaoCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Instruções de Uso *',
                      hintText: 'Ex: Utilizar em caso de enjoo',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe as instruções de uso.'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _bulaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Link da Bula (opcional)',
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Switch Uso Cotidiano / Eventual
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        _isContinuo
                            ? 'Uso Cotidiano (Contínuo)'
                            : 'Uso Eventual (SOS / Se necessário)',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        _isContinuo
                            ? 'Aparece na rotina diária de horários'
                            : 'Fica disponível na aba de remédios eventuais',
                      ),
                      activeThumbColor: AppTheme.primary,
                      value: _isContinuo,
                      onChanged: (val) {
                        setState(() {
                          _isContinuo = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campos de acordo com a seleção
                  if (_isContinuo)
                    TextFormField(
                      controller: _frequenciaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Intervalo entre doses (em horas) *',
                        hintText: 'Ex: 8',
                        prefixIcon: Icon(Icons.schedule_rounded),
                      ),
                      validator: (v) {
                        if (!_isContinuo) return null;
                        final num = int.tryParse(v ?? '');
                        if (num == null || num <= 0) {
                          return 'Informe um intervalo válido em horas.';
                        }
                        return null;
                      },
                    )
                  else if (_carregandoCategorias)
                    const Center(child: CircularProgressIndicator())
                  else if (_categorias.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: const Text(
                        'Nenhuma categoria encontrada no banco. Cadastre categorias na tabela "categoria_remedio_ocasional".',
                        style: TextStyle(fontSize: 13, color: Colors.brown),
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: _idCategoriaSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Categoria do Remédio Eventual *',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _categorias.map((cat) {
                        return DropdownMenuItem<int>(
                          value:
                              cat['id_categoria_medicamento_ocasional'] as int,
                          child: Text(cat['nome'] as String),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _idCategoriaSelecionada = val),
                      validator: (val) => (!_isContinuo && val == null)
                          ? 'Selecione uma categoria.'
                          : null,
                    ),

                  const SizedBox(height: 32),

                  // Botão Salvar
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _salvarMedicamento,
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
                                : 'Cadastrar Medicamento'),
                      ),
                    ),
                  ),

                  // Botão Excluir (visível no corpo quando estiver editando)
                  if (_isEditing) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.danger,
                          side: const BorderSide(color: AppTheme.danger),
                        ),
                        onPressed: _isSaving ? null : _excluirPrescricao,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Excluir este medicamento'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}