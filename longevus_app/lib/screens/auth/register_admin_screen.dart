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
  int _currentStep = 0;
  bool _isLoading = false;

  // Campos tabela `cuidador`
  final _adminNameCtrl = TextEditingController();
  final _adminAbbrCtrl = TextEditingController();
  final _adminCpfCtrl = TextEditingController();
  final _adminPhoneCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPassCtrl = TextEditingController();

  // Campos tabela `longevo` + `longevo_cuidador`
  final _elderNameCtrl = TextEditingController();
  final _elderNicknameCtrl = TextEditingController();
  final _elderAgeCtrl = TextEditingController();
  final _elderCpfCtrl = TextEditingController();
  final _relationshipCtrl = TextEditingController(text: 'Filho(a)');

  Future<void> _finishRegistration() async {
    if (_adminEmailCtrl.text.trim().isEmpty ||
        _adminPassCtrl.text.trim().length < 6 ||
        _elderNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha e-mail, senha (mín. 6 caracteres) e o nome do idoso.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      // 1. Cria autenticação no Supabase Auth (senha segura com hash nativo)
      await supabase.auth.signUp(
        email: _adminEmailCtrl.text.trim(),
        password: _adminPassCtrl.text.trim(),
      );

      // 2. Insere na tabela `cuidador` e retorna o `id_cuidador` gerado
      final cuidadorRes = await supabase
          .from('cuidador')
          .insert({
            'nome_completo': _adminNameCtrl.text.trim(),
            'abreviatura': _adminAbbrCtrl.text.trim().isEmpty
                ? _adminNameCtrl.text.trim().split(' ').first
                : _adminAbbrCtrl.text.trim(),
            'cpf': _adminCpfCtrl.text.trim(),
            'email': _adminEmailCtrl.text.trim(),
            'senha': 'gerenciado_pelo_supabase_auth',
            'telefone': _adminPhoneCtrl.text.trim(),
          })
          .select('id_cuidador')
          .single();

      final int idCuidador = cuidadorRes['id_cuidador'];

      // 3. Insere na tabela `longevo` e retorna o `id_longevo` gerado
      final longevoRes = await supabase
          .from('longevo')
          .insert({
            'nome_completo': _elderNameCtrl.text.trim(),
            'idade': int.tryParse(_elderAgeCtrl.text.trim()),
            'cpf': _elderCpfCtrl.text.trim(),
          })
          .select('id_longevo')
          .single();

      final int idLongevo = longevoRes['id_longevo'];

      // 4. Cria vínculo na tabela `longevo_cuidador` como Administrador (`admin: true`)
      await supabase.from('longevo_cuidador').insert({
        'id_longevo': idLongevo,
        'id_cuidador': idCuidador,
        'admin': true,
        'apelido_longevo': _elderNicknameCtrl.text.trim().isEmpty
            ? _elderNameCtrl.text.trim().split(' ').first
            : _elderNicknameCtrl.text.trim(),
        'relacionamento': _relationshipCtrl.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro concluído com sucesso!'),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => SelectElderScreen(cuidadorId: idCuidador),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na autenticação: ${e.message}'), backgroundColor: AppTheme.danger),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar no banco: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta da família')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == 0) {
                  setState(() => _currentStep = 1);
                } else {
                  _finishRegistration();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                } else {
                  Navigator.pop(context);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: Text(
                            _currentStep == 0 ? 'Próximo: Dados do Idoso' : 'Concluir Cadastro',
                          ),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Voltar'),
                        ),
                      ]
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  isActive: _currentStep >= 0,
                  title: const Text('Seus dados'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Você será o Administrador principal e poderá convidar outros familiares.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _adminNameCtrl,
                        decoration: const InputDecoration(labelText: 'Seu nome completo'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _adminAbbrCtrl,
                              decoration: const InputDecoration(labelText: 'Apelido / Abreviação'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _adminCpfCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Seu CPF'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _adminPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Telefone / WhatsApp'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _adminEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'E-mail de acesso'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _adminPassCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Senha (mín. 6 dígitos)'),
                      ),
                    ],
                  ),
                ),
                Step(
                  isActive: _currentStep >= 1,
                  title: const Text('Perfil do Idoso'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cadastre a pessoa idosa que receberá os cuidados.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _elderNameCtrl,
                        decoration: const InputDecoration(labelText: 'Nome completo do idoso'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _elderNicknameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Apelido carinhoso (ex: Dona Tereza, Pai)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _elderCpfCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'CPF do idoso'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _elderAgeCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Idade'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _relationshipCtrl,
                        decoration: const InputDecoration(labelText: 'Seu parentesco / relação'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}