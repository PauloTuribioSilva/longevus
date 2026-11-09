import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/longevo_model.dart';

class InviteCaregiverScreen extends StatefulWidget {
  final LongevoVinculo vinculo;
  const InviteCaregiverScreen({super.key, required this.vinculo});

  @override
  State<InviteCaregiverScreen> createState() => _InviteCaregiverScreenState();
}

class _InviteCaregiverScreenState extends State<InviteCaregiverScreen> {
  final _supabase = Supabase.instance.client;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _relationshipCtrl = TextEditingController();
  final _tempPassCtrl = TextEditingController(text: 'longevus123');

  bool _isAdmin = false;
  bool _isSaving = false;
  late Future<List<dynamic>> _teamFuture;

  @override
  void initState() {
    super.initState();
    _teamFuture = _fetchCaregivers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _relationshipCtrl.dispose();
    _tempPassCtrl.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _fetchCaregivers() async {
    final response = await _supabase
        .from('longevo_cuidador')
        .select('id_longevo_cuidador, admin, relacionamento, cuidador(*)')
        .eq('id_longevo', widget.vinculo.idLongevo);

    return response as List<dynamic>;
  }

  Future<void> _addCaregiver() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha pelo menos o nome e o e-mail do cuidador.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      int idCuidador;

      final existingUser = await _supabase
          .from('cuidador')
          .select('id_cuidador')
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        idCuidador = existingUser['id_cuidador'];
      } else {
        final insertedUser = await _supabase
            .from('cuidador')
            .insert({
              'nome_completo': name,
              'abreviatura': name.split(' ').first,
              'cpf': '',
              'email': email,
              'senha': _tempPassCtrl.text.trim(),
              'telefone': _phoneCtrl.text.trim(),
            })
            .select('id_cuidador')
            .single();

        idCuidador = insertedUser['id_cuidador'];
      }

      final existingLink = await _supabase
          .from('longevo_cuidador')
          .select('id_longevo_cuidador')
          .eq('id_longevo', widget.vinculo.idLongevo)
          .eq('id_cuidador', idCuidador)
          .maybeSingle();

      if (existingLink != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este cuidador já faz parte da equipe deste idoso.'),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }

      await _supabase.from('longevo_cuidador').insert({
        'id_longevo': widget.vinculo.idLongevo,
        'id_cuidador': idCuidador,
        'admin': _isAdmin,
        'apelido_longevo': widget.vinculo.apelidoLongevo,
        'relacionamento': _relationshipCtrl.text.trim().isEmpty
            ? 'Cuidador'
            : _relationshipCtrl.text.trim(),
      });

      final addedAsAdmin = _isAdmin;

      _nameCtrl.clear();
      _emailCtrl.clear();
      _phoneCtrl.clear();
      _relationshipCtrl.clear();

      setState(() {
        _isAdmin = false;
        _teamFuture = _fetchCaregivers();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$name adicionado como ${addedAsAdmin ? "Administrador" : "Cuidador Comum"}!',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao vincular cuidador: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleRole(int idVinculo, bool currentIsAdmin) async {
    await _supabase
        .from('longevo_cuidador')
        .update({'admin': !currentIsAdmin})
        .eq('id_longevo_cuidador', idVinculo);

    setState(() {
      _teamFuture = _fetchCaregivers();
    });
  }

  Future<void> _removeCaregiver(int idVinculo) async {
    await _supabase
        .from('longevo_cuidador')
        .delete()
        .eq('id_longevo_cuidador', idVinculo);

    setState(() {
      _teamFuture = _fetchCaregivers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipe de Cuidadores')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group_add, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gerenciando cuidadores de ${widget.vinculo.apelidoLongevo}.',
                      style: const TextStyle(
                        color: AppTheme.primaryStrong,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Convidar novo cuidador',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryStrong,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome completo do cuidador',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail de acesso',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telefone'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _relationshipCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Parentesco / Função',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tempPassCtrl,
              decoration: const InputDecoration(
                labelText: 'Senha inicial (caso seja primeiro acesso)',
                helperText: 'Informe esta senha para o cuidador entrar no app.',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nível de permissão',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryStrong,
              ),
            ),
            const SizedBox(height: 8),
            _buildRoleOption(
              title: 'Usuário Comum (Cuidador)',
              subtitle:
                  'Recebe alarmes e confirma doses (Sim / Não), consulta agenda e exames.',
              selected: !_isAdmin,
              onTap: () => setState(() => _isAdmin = false),
            ),
            const SizedBox(height: 10),
            _buildRoleOption(
              title: 'Administrador',
              subtitle:
                  'Acesso total: edita remédios, agenda consultas, sobe exames e convida pessoas.',
              selected: _isAdmin,
              onTap: () => setState(() => _isAdmin = true),
            ),
            const SizedBox(height: 20),
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _addCaregiver,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Vincular à equipe'),
                  ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Cuidadores vinculados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryStrong,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<dynamic>>(
              future: _teamFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Erro ao carregar equipe: ${snapshot.error}');
                }
                final team = snapshot.data ?? [];
                if (team.isEmpty) {
                  return const Text('Nenhum cuidador encontrado.');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: team.length,
                  itemBuilder: (context, index) {
                    final row = team[index] as Map<String, dynamic>;
                    final cuidador = row['cuidador'] as Map<String, dynamic>;
                    final bool isAdm = row['admin'] ?? false;
                    final int idVinculo = row['id_longevo_cuidador'];

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppTheme.line),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAdm
                              ? AppTheme.primarySoft
                              : AppTheme.successSoft,
                          child: Text(
                            (cuidador['nome_completo'] ?? 'C')[0]
                                .toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isAdm
                                  ? AppTheme.primary
                                  : AppTheme.success,
                            ),
                          ),
                        ),
                        title: Text(
                          cuidador['nome_completo'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${row['relacionamento']} • ${isAdm ? "Administrador" : "Usuário Comum"}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'toggle') {
                              _toggleRole(idVinculo, isAdm);
                            } else if (value == 'remove') {
                              _removeCaregiver(idVinculo);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(
                                isAdm
                                    ? 'Tornar Usuário Comum'
                                    : 'Promover a Admin',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'remove',
                              child: Text(
                                'Remover da equipe',
                                style: TextStyle(color: AppTheme.danger),
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
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.primary : AppTheme.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}