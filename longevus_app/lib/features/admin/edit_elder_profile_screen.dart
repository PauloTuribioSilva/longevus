import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/photo_picker_avatar.dart';

class EditElderProfileScreen extends StatefulWidget {
  final Map<String, dynamic> longevo;

  const EditElderProfileScreen({super.key, required this.longevo});

  @override
  State<EditElderProfileScreen> createState() => _EditElderProfileScreenState();
}

class _EditElderProfileScreenState extends State<EditElderProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _idadeCtrl;
  late final TextEditingController _cpfCtrl;

  XFile? _novaFoto;
  Uint8List? _novaFotoBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(
      text: widget.longevo['nome_completo'] ?? '',
    );
    _idadeCtrl = TextEditingController(
      text: widget.longevo['idade']?.toString() ?? '',
    );
    _cpfCtrl = TextEditingController(
      text: widget.longevo['cpf'] ?? '',
    );
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _idadeCtrl.dispose();
    _cpfCtrl.dispose();
    super.dispose();
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

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final int idLongevo = widget.longevo['id_longevo'] as int;
      String? fotoUrl = widget.longevo['foto_url'] as String?;

      // 1. Se escolheu uma foto nova, envia para o Storage primeiro
      if (_novaFoto != null) {
        final uploadedUrl = await StorageService.uploadImagem(
          arquivo: _novaFoto!,
          pasta: 'idosos',
          identificador: 'longevo_$idLongevo',
        );
        if (uploadedUrl != null) {
          fotoUrl = uploadedUrl;
        }
      }

      // 2. Atualiza os dados na tabela 'longevo'
      await _supabase.from('longevo').update({
        'nome_completo': _nomeCtrl.text.trim(),
        'idade': int.tryParse(_idadeCtrl.text.trim()),
        'cpf': _cpfCtrl.text.trim(),
        'foto_url': fotoUrl,
      }).eq('id_longevo', idLongevo);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil do idoso atualizado com sucesso!'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
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
      appBar: AppBar(title: const Text('Editar Perfil do Idoso')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PhotoPickerAvatar(
                    currentPhotoUrl: widget.longevo['foto_url'],
                    selectedImageBytes: _novaFotoBytes,
                    onTapPick: _escolherFoto,
                    fallbackIcon: Icons.elderly_rounded,
                    isCircle: true,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toque na câmera para alterar a foto',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nomeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe o nome.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _idadeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Idade',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cpfCtrl,
                    decoration: const InputDecoration(
                      labelText: 'CPF',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe o CPF.' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _salvarAlteracoes,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_isSaving ? 'Salvando...' : 'Salvar Alterações'),
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