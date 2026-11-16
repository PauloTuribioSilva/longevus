import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_menu_card.dart';
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
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppTheme.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: AppTheme.coloredShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondary.withValues(alpha: 0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    vinculo.apelidoLongevo.isNotEmpty
                        ? vinculo.apelidoLongevo[0].toUpperCase()
                        : 'L',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryStrong,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vinculo.nomeCompleto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vinculo.idade ?? "--"} anos • ${vinculo.isAdmin ? "Administrador" : "Cuidador"}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const SectionLabel(text: 'ROTINA DE CUIDADOS'),

          PremiumMenuCard(
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

          PremiumMenuCard(
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

          PremiumMenuCard(
            icon: Icons.calendar_month,
            title: 'Agenda de consultas',
            subtitle: 'Datas, locais e quem vai levar',
            onTap: () {
              // Próximo módulo: AppointmentsScreen
            },
          ),

          PremiumMenuCard(
            icon: Icons.folder_shared,
            title: 'Exames e documentos',
            subtitle: 'Laudos em PDF e carteirinha do plano',
            onTap: () {
              // Próximo módulo: ExamsScreen
            },
          ),

          if (vinculo.isAdmin) ...[
            const SizedBox(height: 24),
            const SectionLabel(text: 'ADMINISTRAÇÃO', color: AppTheme.primary),
            PremiumMenuCard(
              icon: Icons.group_add,
              title: 'Administrar cuidadores',
              subtitle: 'Convidar familiares e definir permissões',
              highlighted: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InviteCaregiverScreen(vinculo: vinculo),
                  ),
                );
              },
            ),
            PremiumMenuCard(
              icon: Icons.edit_note,
              title: 'Gerenciar prescrições e perfil',
              subtitle: 'Editar remédios, horários e dados médicos',
              highlighted: true,
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
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
}