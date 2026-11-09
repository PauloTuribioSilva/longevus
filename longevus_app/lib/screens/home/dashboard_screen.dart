import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/longevo_model.dart';
import '../admin/invite_caregiver_screen.dart';
import '../care/alarm_alert_screen.dart';
import '../care/daily_meds_screen.dart';
import '../care/occasional_meds_screen.dart';

class DashboardScreen extends StatelessWidget {
  final LongevoVinculo vinculo;
  final int cuidadorId;

  const DashboardScreen({
    super.key,
    required this.vinculo,
    required this.cuidadorId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          vinculo.apelidoLongevo,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Simular Alarme de Remédio',
            icon: const Icon(
              Icons.notifications_active,
              color: AppTheme.secondary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlarmAlertScreen(
                    elderName: vinculo.apelidoLongevo,
                    cuidadorId: cuidadorId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryStrong],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.secondary,
                  child: Text(
                    vinculo.apelidoLongevo.isNotEmpty
                        ? vinculo.apelidoLongevo[0].toUpperCase()
                        : 'L',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryStrong,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vinculo.nomeCompleto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vinculo.idade ?? "--"} anos • ${vinculo.isAdmin ? "Administrador" : "Cuidador"}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ROTINA DE CUIDADOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),

          _menuCard(
            icon: Icons.alarm,
            title: 'Remédios do dia a dia',
            subtitle: 'Horários contínuos e confirmações',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailyMedsScreen(
                    vinculo: vinculo,
                    cuidadorId: cuidadorId,
                  ),
                ),
              );
            },
          ),

          _menuCard(
            icon: Icons.medication_liquid,
            title: 'Remédios eventuais',
            subtitle: 'Dor, febre e sintomas ocasionais',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OccasionalMedsScreen(
                    vinculo: vinculo,
                    cuidadorId: cuidadorId,
                  ),
                ),
              );
            },
          ),

          _menuCard(
            icon: Icons.calendar_month,
            title: 'Agenda de consultas',
            subtitle: 'Datas, locais e quem vai levar',
            onTap: () {
              // Próximo módulo: AppointmentsScreen
            },
          ),

          _menuCard(
            icon: Icons.folder_shared,
            title: 'Exames e documentos',
            subtitle: 'Laudos em PDF e carteirinha do plano',
            onTap: () {
              // Próximo módulo: ExamsScreen
            },
          ),

          if (vinculo.isAdmin) ...[
            const SizedBox(height: 24),
            const Text(
              'ADMINISTRAÇÃO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _menuCard(
              icon: Icons.group_add,
              title: 'Administrar cuidadores',
              subtitle: 'Convidar familiares e definir permissões',
              isAdminItem: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InviteCaregiverScreen(vinculo: vinculo),
                  ),
                );
              },
            ),
            _menuCard(
              icon: Icons.edit_note,
              title: 'Gerenciar prescrições e perfil',
              subtitle: 'Editar remédios, horários e dados médicos',
              isAdminItem: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DailyMedsScreen(
                      vinculo: vinculo,
                      cuidadorId: cuidadorId,
                    ),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppTheme.secondarySoft,
              foregroundColor: AppTheme.primaryStrong,
              side: const BorderSide(color: AppTheme.secondary),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.swap_horiz),
            label: const Text(
              'Trocar o perfil do idoso',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isAdminItem = false,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: isAdminItem ? AppTheme.primarySoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isAdminItem ? AppTheme.primary.withOpacity(0.2) : AppTheme.line,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isAdminItem ? AppTheme.primary : AppTheme.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isAdminItem ? Colors.white : AppTheme.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}