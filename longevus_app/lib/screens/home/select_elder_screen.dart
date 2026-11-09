import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/longevo_model.dart';
import '../auth/login_screen.dart';
import 'dashboard_screen.dart';

class SelectElderScreen extends StatefulWidget {
  final int cuidadorId;
  const SelectElderScreen({super.key, required this.cuidadorId});

  @override
  State<SelectElderScreen> createState() => _SelectElderScreenState();
}

class _SelectElderScreenState extends State<SelectElderScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<LongevoVinculo>> _idososFuture;

  @override
  void initState() {
    super.initState();
    _idososFuture = _fetchIdosos();
  }

  Future<List<LongevoVinculo>> _fetchIdosos() async {
    final response = await _supabase
        .from('longevo_cuidador')
        .select('admin, apelido_longevo, relacionamento, longevo(*)')
        .eq('id_cuidador', widget.cuidadorId);

    return (response as List).map((row) {
      final longevo = row['longevo'] as Map<String, dynamic>;
      return LongevoVinculo(
        idLongevo: longevo['id_longevo'],
        nomeCompleto: longevo['nome_completo'] ?? '',
        idade: longevo['idade'],
        cpf: longevo['cpf'] ?? '',
        apelidoLongevo: row['apelido_longevo'] ?? longevo['nome_completo'] ?? '',
        relacionamento: row['relacionamento'] ?? '',
        isAdmin: row['admin'] ?? false,
      );
    }).toList();
  }

  void _openAddElderDialog() {
    final nameCtrl = TextEditingController();
    final nickCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final cpfCtrl = TextEditingController();
    final relCtrl = TextEditingController(text: 'Filho(a)');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      'Cadastrar novo idoso',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryStrong,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nome completo'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nickCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Apelido carinhoso (ex: Vó Maria)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: cpfCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'CPF'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: ageCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Idade'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: relCtrl,
                      decoration: const InputDecoration(labelText: 'Seu parentesco'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (nameCtrl.text.trim().isEmpty) return;

                                setModalState(() => isSaving = true);

                                try {
                                  final longevoRes = await _supabase
                                      .from('longevo')
                                      .insert({
                                        'nome_completo': nameCtrl.text.trim(),
                                        'idade': int.tryParse(ageCtrl.text.trim()),
                                        'cpf': cpfCtrl.text.trim(),
                                      })
                                      .select('id_longevo')
                                      .single();

                                  await _supabase.from('longevo_cuidador').insert({
                                    'id_longevo': longevoRes['id_longevo'],
                                    'id_cuidador': widget.cuidadorId,
                                    'admin': true,
                                    'apelido_longevo': nickCtrl.text.trim().isEmpty
                                        ? nameCtrl.text.trim().split(' ').first
                                        : nickCtrl.text.trim(),
                                    'relacionamento': relCtrl.text.trim(),
                                  });

                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);

                                  if (!mounted) return;
                                  setState(() {
                                    _idososFuture = _fetchIdosos();
                                  });
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erro ao salvar perfil: $e'),
                                      backgroundColor: AppTheme.danger,
                                    ),
                                  );
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Salvar perfil'),
                      ),
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

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Longevus',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Adicionar outro idoso',
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: _openAddElderDialog,
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'De quem você está cuidando hoje?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryStrong,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecione um perfil para visualizar medicamentos, consultas e exames.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<LongevoVinculo>>(
                future: _idososFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erro ao carregar: ${snapshot.error}'),
                    );
                  }
                  final idosos = snapshot.data ?? [];
                  if (idosos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Nenhum idoso vinculado a este cuidador.',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openAddElderDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Cadastrar primeiro idoso'),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: idosos.length,
                    itemBuilder: (context, index) {
                      final item = idosos[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DashboardScreen(
                                vinculo: item,
                                cuidadorId: widget.cuidadorId,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppTheme.line),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: AppTheme.secondarySoft,
                                child: Text(
                                  item.apelidoLongevo.isNotEmpty
                                      ? item.apelidoLongevo[0].toUpperCase()
                                      : 'L',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primaryStrong,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.apelidoLongevo,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryStrong,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: item.isAdmin
                                      ? AppTheme.primarySoft
                                      : AppTheme.successSoft,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  item.isAdmin ? 'Admin' : 'Cuidador',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: item.isAdmin
                                        ? AppTheme.primary
                                        : AppTheme.success,
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
            ),
          ],
        ),
      ),
    );
  }
}