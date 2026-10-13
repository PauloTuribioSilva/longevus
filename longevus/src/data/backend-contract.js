export const backendContract = {
  status: 'draft',
  scope: 'frontend-only',
  description: 'Estrutura de referência para integração futura do backend. Este arquivo não deve conter dados reais, apenas contratos e exemplos de payload.',
  modules: {
    auth: {
      note: 'Autenticação e perfis de acesso a serem implementados no backend.',
      endpoints: [
        'POST /api/auth/login',
        'POST /api/auth/logout',
        'GET /api/auth/me'
      ]
    },
    family: {
      note: 'Dados da família e do paciente sensíveis; não devem ser expostos no frontend em produção sem autenticação.',
      endpoints: [
        'GET /api/family/profile',
        'PATCH /api/family/profile',
        'GET /api/family/team',
        'POST /api/family/team'
      ]
    },
    care: {
      note: 'Agenda, medicamentos, exames e alertas do cuidado.',
      endpoints: [
        'GET /api/care/appointments',
        'POST /api/care/appointments',
        'PATCH /api/care/appointments/:id',
        'DELETE /api/care/appointments/:id',
        'GET /api/care/medications',
        'POST /api/care/medications',
        'PATCH /api/care/medications/:id',
        'DELETE /api/care/medications/:id',
        'GET /api/care/documents',
        'POST /api/care/documents',
        'PATCH /api/care/documents/:id',
        'DELETE /api/care/documents/:id',
        'GET /api/care/alerts',
        'POST /api/care/alerts',
        'PATCH /api/care/alerts/:id',
        'DELETE /api/care/alerts/:id'
      ]
    }
  },
  examplePayloads: {
    profile: {
      id: 'uuid',
      elderName: 'string',
      age: 0,
      bloodType: 'A+',
      allergies: 'string',
      emergencyContact: 'string'
    },
    appointment: {
      id: 'uuid',
      title: 'string',
      date: 'YYYY-MM-DD',
      time: 'HH:mm',
      location: 'string',
      notes: 'string'
    },
    medication: {
      id: 'uuid',
      name: 'string',
      type: 'scheduled',
      dosage: 'string',
      times: 'string',
      responsible: 'string',
      instruction: 'string'
    }
  }
};
