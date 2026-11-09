import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../home/select_elder_screen.dart';

class RegisterAdminScreen extends StatefulWidget {
  const RegisterAdminScreen({super.key});

  @override
  State<RegisterAdminScreen> createState() => _RegisterAdminScreenState();
}

class _RegisterAdminScreenState extends State<RegisterAdminScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Dados do Administrador (Cuidador Principal)
  final _adminNameCtrl = TextEditingController();
  final _adminPhoneCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPasswordCtrl = TextEditingController();

  // Dados do Primeiro Idoso
  final _elderNameCtrl = TextEditingController();
  final _elderNickCtrl = TextEditingController();
  final _elderCpfCtrl = TextEditingController();
  final _elderAgeCtrl = TextEditingController();
  final _relationshipCtrl = TextEditingController(text: 'Filho(a)');

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _adminNameCtrl.dispose();
    _adminPhoneCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPasswordCtrl.dispose();
    _elderNameCtrl.dispose();
    _elderNickCtrl.dispose();
    _elderCpfCtrl.dispose();
    _elderAgeCtrl.dispose();
    _relationshipCtrl.dispose();
    super.dispose();
  }

  Future<void> _registerAdminAndElder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _adminEmailCtrl.text.trim();
      final password = _adminPasswordCtrl.text;

      // 1. Cria o usuário no Supabase Auth
      final authRes = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authRes.user == null) {
        throw const AuthException('Não foi possível criar a conta de acesso.');
      }

      // 2. Insere o cuidador (administrador) na tabela 'cuidador'
      final cuidadorRes = await _supabase
          .from('cuidador')
          .insert({
            'nome': _adminNameCtrl.text.trim(),
            'telefone': _adminPhoneCtrl.text.trim(),
            'email': email,
          })
          .select('id_cuidador')
          .single();

      final int cuidadorId = cuidadorRes['id_cuidador'] as int;

      // 3. Insere o primeiro idoso na tabela 'longevo'
      final longevoRes = await _supabase
          .from('longevo')
          .insert({
            'nome_completo': _elderNameCtrl.text.trim(),
            'cpf': _elderCpfCtrl.text.trim(),
            'idade': int.tryParse(_elderAgeCtrl.text.trim()),
          })
          .select('id_longevo')
          .single();

      final int longevoId = longevoRes['id_longevo'] as int;

      // 4. Cria o vínculo como Administrador (admin = true)
      final apelido = _elderNickCtrl.text.trim().isEmpty
          ? _elderNameCtrl.text.trim().split(' ').first
          : _elderNickCtrl.text.trim();

      await _supabase.from('longevo_cuidador').insert({
        'id_longevo': longevoId,
        'id_cuidador': cuidadorId,
        'admin': true,
        'apelido_longevo': apelido,
        'relacionamento': _relationshipCtrl.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro concluído com sucesso!'),
          backgroundColor: AppTheme.success,
        ),
      );

      // 5. Entra direto na tela de seleção de idosos
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => SelectElderScreen(cuidadorId: cuidadorId),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError('Erro de autenticação: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _showError('Erro ao finalizar cadastro: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Criar Conta Administrador',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SEÇÃO 1: DADOS DO ADMINISTRADOR
                    const Text(
                      '1. Seus dados (Administrador)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryStrong,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Você poderá convidar outros cuidadores depois.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _adminNameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Seu nome completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe seu nome.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _adminPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Telefone / WhatsApp',
                        hintText: '(14) 99999-9999',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe seu telefone.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _adminEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'E-mail de acesso',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe seu e-mail.';
                        }
                        if (!v.contains('@')) return 'E-mail inválido.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _adminPasswordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Crie uma senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Mínimo de 6 caracteres.'
                          : null,
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(),
                    ),

                    // SEÇÃO 2: DADOS DO PRIMEIRO IDOSO
                    const Text(
                      '2. Primeiro idoso sob cuidado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryStrong,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Cadastre quem receberá os cuidados principais.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _elderNameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo do idoso',
                        prefixIcon: Icon(Icons.elderly),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o nome do idoso.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _elderNickCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Apelido carinhoso (ex: Vó Maria, Pai)',
                        prefixIcon: Icon(Icons.favorite_border),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _elderCpfCtrl,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'CPF do idoso',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Informe o CPF.'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _elderAgeCtrl,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Idade',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _relationshipCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Seu parentesco / vínculo (ex: Filho, Neta)',
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                    ),

                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerAdminAndElder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Concluir cadastro',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}