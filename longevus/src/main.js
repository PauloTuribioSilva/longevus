import './styles.css';
import { emptyState } from './data/emptyState.js';

const STORAGE_KEY = 'longevus-data-v1';
const app = document.querySelector('#app');
const currentDate = new Date();
const monthFormatter = new Intl.DateTimeFormat('pt-BR', { month: 'long', year: 'numeric' });
const weekdayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

const state = {
  activeView: 'overview',
  activeRole: 'admin',
  shownMonth: new Date(currentDate.getFullYear(), currentDate.getMonth(), 1),
  data: loadData(),
  authenticated: false,
  toastTimer: null
};

function loadData() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || 'null');
    if (!saved) return structuredClone(emptyState);
    return {
      ...structuredClone(emptyState),
      ...saved,
      profile: { ...structuredClone(emptyState.profile), ...(saved.profile || {}) },
      medications: Array.isArray(saved.medications) ? saved.medications : [],
      appointments: Array.isArray(saved.appointments) ? saved.appointments : [],
      documents: Array.isArray(saved.documents) ? saved.documents : [],
      alerts: Array.isArray(saved.alerts) ? saved.alerts : [],
      caregivers: Array.isArray(saved.caregivers) ? saved.caregivers : []
    };
  } catch {
    return structuredClone(emptyState);
  }
}

function saveData() {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state.data));
  } catch {
    showToast('Não foi possível salvar localmente neste navegador.');
  }
}

function escapeHtml(value) {
  return String(value ?? '').replace(/[&<>"']/g, (char) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;'
  }[char]));
}

function formatDate(dateString) {
  if (!dateString) return 'Data não informada';
  const date = new Date(`${dateString}T00:00:00`);
  return new Intl.DateTimeFormat('pt-BR', { day: 'numeric', month: 'short', year: 'numeric' }).format(date)
    .replace(' de ', ' ')
    .replace('.', '');
}

function makeId() {
  return window.crypto?.randomUUID?.() ?? `id-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function localDateString(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function renderLoginScreen() {
  return `
    <div class="auth-screen">
      <div class="auth-panel">
        <div class="auth-visual">
          <div class="auth-brand" aria-label="Longevus logo">
            <div class="brand-mark auth-brand-mark">L</div>
            <div>
              <strong>Longevus</strong>
              <span>cuidado em conjunto</span>
            </div>
          </div>

          <div class="auth-hero">
            <p class="eyebrow">Acesso ao painel</p>
            <h1>Organize a rotina da família com clareza.</h1>
            <p>Centralize compromissos, medicamentos, exames e lembretes em um ambiente seguro e visualmente simples.</p>
          </div>

          <div class="auth-highlights">
            <div class="highlight-pill"><span class="dot"></span> Agenda compartilhada</div>
            <div class="highlight-pill"><span class="dot"></span> Medicamentos e lembretes</div>
            <div class="highlight-pill"><span class="dot"></span> Acompanhamento familiar</div>
          </div>
        </div>

        <div class="auth-form-wrap">
          <div class="auth-copy">
            <p class="eyebrow">Entrar</p>
            <h2>Bem-vindo de volta</h2>
          </div>

          <form class="auth-form" id="login-form">
            <div class="field">
              <label for="login-email">E-mail</label>
              <input id="login-email" name="email" type="email" placeholder="seu@email.com" autocomplete="email" required />
            </div>

            <div class="field">
              <label for="login-password">Senha</label>
              <input id="login-password" name="password" type="password" placeholder="••••••••" autocomplete="current-password" required />
            </div>

            <div class="auth-row">
              <label class="checkbox-wrap">
                <input type="checkbox" name="remember" checked />
                <span>Lembrar acesso</span>
              </label>
              <button type="button" class="link-btn">Esqueci a senha</button>
            </div>

            <button type="submit" class="primary-btn auth-submit">Entrar no painel</button>
            <p class="auth-demo">Demo: admin@longevus.com / longevus123</p>
          </form>
        </div>
      </div>
    </div>
  `;
}

function renderApp() {
  if (!state.authenticated) {
    app.innerHTML = renderLoginScreen();
    bindEvents();
    return;
  }

  app.innerHTML = `
    <div class="app-shell">
      <header class="app-header">
        <div class="brand-wrap">
          <div class="brand-mark">L</div>
          <div class="brand-copy">
            <strong>longevus</strong>
            <span>cuidado em conjunto</span>
          </div>
        </div>
        <div class="user-box">
          <div class="user-badge">
            <div class="user-avatar">${escapeHtml(state.data.elder?.charAt(0) || 'L')}</div>
            <div class="user-meta">
              <strong>${escapeHtml(state.data.elder || 'Minha família')}</strong>
              <span>${escapeHtml(state.activeRole === 'admin' ? 'Administrador da família' : 'Cuidador')}</span>
            </div>
          </div>
          <button class="ghost-btn logout-btn" type="button" data-action="logout">Sair</button>
          <div class="custom-select role-switch-wrap" data-role-select>
            <button class="role-switch" id="role-switch" type="button" aria-expanded="false" aria-haspopup="listbox">
              <span class="role-switch-label">${state.activeRole === 'admin' ? 'Administrador da família' : 'Cuidador (consulta)'}</span>
            </button>
            <div class="role-switch-menu" role="listbox" aria-label="Permissões do painel">
              <button type="button" class="role-option ${state.activeRole === 'admin' ? 'selected' : ''}" data-role-option="admin">Administrador da família</button>
              <button type="button" class="role-option ${state.activeRole === 'caregiver' ? 'selected' : ''}" data-role-option="caregiver">Cuidador (consulta)</button>
            </div>
          </div>
        </div>
      </header>

      <div class="layout">
        <aside class="sidebar">
          <div class="nav-section">
            <p class="nav-title">Organização</p>
            <nav class="nav-list" aria-label="Navegação principal">
              <button class="nav-button ${state.activeView === 'overview' ? 'active' : ''}" data-view="overview" type="button">
                <span class="nav-icon" aria-hidden="true">
                  <svg viewBox="0 0 24 24"><path d="M4 4.75h7.25v6.5H4zm8.75 0H20v4.5h-7.25zm0 7.5H20v7.25h-7.25zM4 12.5h7.25v8.75H4z"/></svg>
                </span>
                <span>Visão geral</span>
              </button>
              <button class="nav-button ${state.activeView === 'profile' ? 'active' : ''}" data-view="profile" type="button">
                <span class="nav-icon" aria-hidden="true">
                  <svg viewBox="0 0 24 24"><path d="M12 12.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Zm-6.5 6.5c1.1-2.2 3.1-3.4 6.5-3.4s5.4 1.2 6.5 3.4"/></svg>
                </span>
                <span>Perfil do idoso</span>
              </button>
              <button class="nav-button ${state.activeView === 'medications' ? 'active' : ''}" data-view="medications" type="button">
                <span class="nav-icon" aria-hidden="true">
                  <svg viewBox="0 0 24 24"><path d="M8 6.5h8a2.5 2.5 0 0 1 2.5 2.5v6A2.5 2.5 0 0 1 16 17.5H8A2.5 2.5 0 0 1 5.5 15V9A2.5 2.5 0 0 1 8 6.5Zm3 0V3.75m2 2.75V3.75M9.5 13h5"/></svg>
                </span>
                <span>Medicamentos</span>
              </button>
              <button class="nav-button ${state.activeView === 'agenda' ? 'active' : ''}" data-view="agenda" type="button">
                <span class="nav-icon" aria-hidden="true">
                  <svg viewBox="0 0 24 24"><path d="M7 3.75v2.5M17 3.75v2.5M4.5 8.25h15M6 5.5h12a1.5 1.5 0 0 1 1.5 1.5v11A1.5 1.5 0 0 1 18 19.5H6A1.5 1.5 0 0 1 4.5 18V7A1.5 1.5 0 0 1 6 5.5Z"/></svg>
                </span>
                <span>Agenda</span>
              </button>
              <button class="nav-button ${state.activeView === 'documents' ? 'active' : ''}" data-view="documents" type="button">
                <span class="nav-icon" aria-hidden="true">
                  <svg viewBox="0 0 24 24"><path d="M7 3.75h7l4 4V18a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V5.75a2 2 0 0 1 2-2Zm7 1.5v4h4M8.5 12.5h7M8.5 16h7"/></svg>
                </span>
                <span>Exames e laudos</span>
              </button>
              <button class="nav-button ${state.activeView === 'alerts' ? 'active' : ''}" data-view="alerts" type="button">
                <span class="nav-icon" aria-hidden="true">
                  <svg viewBox="0 0 24 24"><path d="M9 18.5h6M10 18.5V11a2 2 0 1 1 4 0v7.5M6.5 16.5h11l-1.1-8.3A4.9 4.9 0 0 0 11.5 4a4.9 4.9 0 0 0-4.9 4.2L6.5 16.5Z"/></svg>
                </span>
                <span>Avisos</span>
              </button>
              <button class="nav-button ${state.activeView === 'team' ? 'active' : ''}" data-view="team" type="button">
                <span class="nav-icon" aria-hidden="true">
                  <svg viewBox="0 0 24 24"><path d="M9 11.5A2.75 2.75 0 1 0 9 6a2.75 2.75 0 0 0 0 5.5Zm6 1.25a2.25 2.25 0 1 0 0-4.5 2.25 2.25 0 0 0 0 4.5Zm-10.5 6.5c.7-2.2 2.8-3.5 5.7-3.5s5 1.3 5.7 3.5M16.5 18.25c.7-1.7 2.1-2.8 4-3.2"/></svg>
                </span>
                <span>Equipe</span>
              </button>
            </nav>
          </div>

          <div class="sidebar-card">
            <strong>Cuidado compartilhado</strong>
            <p>Uma rotina mais organizada para quem cuida e para quem recebe cuidado.</p>
          </div>
        </aside>

        <main class="main-panel">
          ${renderCurrentView()}
        </main>
      </div>
    </div>

    <dialog class="modal" id="record-dialog">
      <div class="modal-header">
        <h3 id="dialog-title">Adicionar registro</h3>
        <p id="dialog-subtitle">Preencha os campos abaixo.</p>
      </div>
      <form class="modal-form" id="record-form"></form>
    </dialog>

    <div class="toast" id="toast" hidden></div>
  `;

  bindEvents();
}

function renderCurrentView() {
  const views = {
    overview: renderOverview,
    profile: renderProfile,
    medications: renderMedications,
    agenda: renderAgenda,
    documents: renderDocuments,
    alerts: renderAlerts,
    team: renderTeam
  };

  return views[state.activeView]?.() || views.overview();
}

function renderHeader(title, subtitle, actionLabel, actionType) {
  const adminAction = state.activeRole === 'admin'
    ? `<button type="button" class="primary-btn" data-action="${actionType}">+ ${actionLabel}</button>`
    : '<span class="tag warning">Modo de consulta</span>';

  return `
    <div class="page-header">
      <div>
        <p class="eyebrow">Longevus</p>
        <h1>${escapeHtml(title)}</h1>
        <p>${escapeHtml(subtitle)}</p>
      </div>
      ${adminAction}
    </div>
  `;
}

function upcomingAppointments(limit = 4) {
  const today = localDateString(new Date());
  return [...state.data.appointments]
    .filter((item) => item.date >= today)
    .sort((a, b) => `${a.date}T${a.time}`.localeCompare(`${b.date}T${b.time}`))
    .slice(0, limit);
}

function renderOverview() {
  const monthAppointments = state.data.appointments.filter((item) => {
    const date = new Date(`${item.date}T00:00:00`);
    return date.getFullYear() === state.shownMonth.getFullYear() && date.getMonth() === state.shownMonth.getMonth();
  });

  return `
    ${renderHeader('Visão geral', 'A rotina e os compromissos da família em um só lugar.', 'Adicionar consulta', 'appointment')}

    <div class="summary-grid">
      <div class="summary-card">
        <span class="label">Consultas neste mês</span>
        <div class="value">${monthAppointments.length}</div>
      </div>
      <div class="summary-card">
        <span class="label">Medicamentos</span>
        <div class="value">${state.data.medications.length}</div>
      </div>
      <div class="summary-card">
        <span class="label">Avisos ativos</span>
        <div class="value">${state.data.alerts.length}</div>
      </div>
    </div>

    <div class="content-grid">
      <section class="panel">
        <div class="panel-header">
          <h2>Calendário compartilhado</h2>
          <div style="display:flex; align-items:center; gap:10px;">
            <button class="ghost-btn" type="button" data-action="previous-month" aria-label="Mês anterior">‹</button>
            <span class="muted">${escapeHtml(monthFormatter.format(state.shownMonth))}</span>
            <button class="ghost-btn" type="button" data-action="next-month" aria-label="Próximo mês">›</button>
          </div>
        </div>
        <div class="calendar-shell">
          <div class="calendar-inner">
            ${weekdayLabels.map((day) => `<div class="calendar-header">${day}</div>`).join('')}
            ${renderCalendarGrid()}
          </div>
        </div>
      </section>

      <aside class="panel">
        <div class="panel-header">
          <h2>Próximas consultas</h2>
          <button class="secondary-btn" type="button" data-view="agenda">Ver agenda</button>
        </div>
        <div class="agenda-list">
          ${renderAppointmentsList(upcomingAppointments(4))}
        </div>
      </aside>
    </div>
  `;
}

function renderCalendarGrid() {
  const year = state.shownMonth.getFullYear();
  const month = state.shownMonth.getMonth();
  const firstDay = new Date(year, month, 1);
  const gridStart = new Date(year, month, 1 - ((firstDay.getDay() + 6) % 7));
  const today = localDateString(new Date());
  const cells = [];

  for (let i = 0; i < 42; i++) {
    const date = new Date(gridStart.getFullYear(), gridStart.getMonth(), gridStart.getDate() + i);
    const dateString = localDateString(date);
    const appointmentsForDay = state.data.appointments.filter((item) => item.date === dateString);
    const classes = ['day-cell'];
    if (date.getMonth() !== month) classes.push('outside');
    if (dateString === today) classes.push('today');

    const pills = appointmentsForDay
      .slice(0, 3)
      .map((item, index) => {
        const variant = index % 3 === 0 ? 'alt' : index % 3 === 1 ? '' : 'success';
        return `<span class="day-pill ${variant}" title="${escapeHtml(item.title)}">${escapeHtml(item.title)}</span>`;
      })
      .join('');

    cells.push(`
      <div class="${classes.join(' ')}">
        <div class="day-number">${date.getDate()}</div>
        <div class="day-events">${pills || ''}</div>
      </div>
    `);
  }

  return cells.join('');
}

function renderAppointmentsList(items) {
  if (!items.length) {
    return '<div class="empty-box">Nenhuma consulta cadastrada.</div>';
  }

  return items.map((item) => {
    const date = new Date(`${item.date}T00:00:00`);
    return `
      <article class="event-item">
        <div class="event-date">
          <strong>${date.getDate()}</strong>
          <span>${new Intl.DateTimeFormat('pt-BR', { month: 'short' }).format(date).replace('.', '')}</span>
        </div>
        <div>
          <p class="item-title">${escapeHtml(item.title)}</p>
          <p class="item-copy">${escapeHtml(item.time)} · ${escapeHtml(item.location || 'Local não informado')} </p>
          <p class="item-copy">${escapeHtml(item.notes || 'Sem observações adicionais')}</p>
          ${state.activeRole === 'admin' ? `<div class="item-actions"><button class="ghost-btn" type="button" data-action="edit" data-type="appointment" data-id="${item.id}">Editar</button><button class="danger-btn" type="button" data-action="delete" data-type="appointment" data-id="${item.id}">Remover</button></div>` : ''}
        </div>
      </article>
    `;
  }).join('');
}

function renderProfile() {
  const profile = state.data.profile;

  return `
    ${renderHeader('Perfil do idoso', 'Informações importantes para toda a rede de cuidado.', 'Editar perfil', 'profile')}

    <div class="two-column">
      <section class="section-stack">
        <div class="panel">
          <div class="panel-header">
            <h2>Informações de saúde</h2>
            <span class="muted">Acesso compartilhado</span>
          </div>
          <div class="scope-card">
            <div class="info-grid">
              <div class="info-box"><span>Nome</span><strong>${escapeHtml(state.data.elder || 'Não informado')}</strong></div>
              <div class="info-box"><span>Idade</span><strong>${escapeHtml(profile.age || 'Não informada')}</strong></div>
              <div class="info-box"><span>Tipo sanguíneo</span><strong>${escapeHtml(profile.bloodType || 'Não informado')}</strong></div>
              <div class="info-box"><span>Contato de emergência</span><strong>${escapeHtml(profile.emergencyContact || 'Não informado')}</strong></div>
              <div class="info-box" style="grid-column: 1 / -1;"><span>Alergias</span><strong>${escapeHtml(profile.allergies || 'Nenhuma informada')}</strong></div>
              <div class="info-box" style="grid-column: 1 / -1;"><span>Condições importantes</span><strong>${escapeHtml(profile.conditions || 'Nenhuma informada')}</strong></div>
              <div class="info-box" style="grid-column: 1 / -1;"><span>Observações</span><strong>${escapeHtml(profile.notes || 'Nenhuma')}</strong></div>
            </div>
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h2>Medicamentos programados</h2>
            <button class="secondary-btn" type="button" data-view="medications">Ver todos</button>
          </div>
          <div class="card-stack">
            ${renderMedicationCards('scheduled')}
          </div>
        </div>
      </section>

      <section class="section-stack">
        <div class="panel">
          <div class="panel-header">
            <h2>Próximas consultas</h2>
            <button class="secondary-btn" type="button" data-view="agenda">Ver agenda</button>
          </div>
          <div class="agenda-list">
            ${renderAppointmentsList(upcomingAppointments(3))}
          </div>
        </div>

        <div class="panel">
          <div class="panel-header">
            <h2>Exames e laudos</h2>
            <button class="secondary-btn" type="button" data-view="documents">Ver todos</button>
          </div>
          <div class="list-stack">
            ${renderDocumentRows(3)}
          </div>
        </div>
      </section>
    </div>
  `;
}

function renderMedicationCards(type) {
  const items = state.data.medications.filter((item) => (item.type || 'scheduled') === type);

  if (!items.length) {
    return '<div class="empty-box">Nenhum medicamento cadastrado.</div>';
  }

  return items.map((item) => `
    <article class="card-item">
      <div class="event-date" style="background: rgba(70, 33, 99, 0.08); color: var(--primary);">
        <strong>${item.name.charAt(0).toUpperCase()}</strong>
      </div>
      <div>
        <p class="item-title">${escapeHtml(item.name)}${item.dosage ? ` · ${escapeHtml(item.dosage)}` : ''}</p>
        <p class="item-copy">${type === 'scheduled' ? `${escapeHtml(item.times || 'Horário não informado')} · ${escapeHtml(item.responsible || 'Responsável não informado')}` : `${escapeHtml(item.purpose || 'Finalidade não informada')}`}</p>
        <p class="item-copy">${escapeHtml(type === 'scheduled' ? (item.note || 'Sem observações') : (item.instruction || 'Sem orientação informada'))}</p>
        ${state.activeRole === 'admin' ? `<div class="item-actions"><button class="ghost-btn" type="button" data-action="edit" data-type="medicine" data-id="${item.id}">Editar</button><button class="danger-btn" type="button" data-action="delete" data-type="medicine" data-id="${item.id}">Remover</button></div>` : ''}
      </div>
    </article>
  `).join('');
}

function renderMedications() {
  return `
    ${renderHeader('Medicamentos', 'Horários programados e medicamentos de uso ocasional.', 'Cadastrar medicamento', 'medicine')}

    <div class="section-stack">
      <div class="panel">
        <div class="panel-header">
          <h2>Uso programado</h2>
          <span class="muted">Horários e responsável</span>
        </div>
        <div class="card-stack">
          ${renderMedicationCards('scheduled')}
        </div>
      </div>

      <div class="panel">
        <div class="panel-header">
          <h2>Uso ocasional</h2>
          <span class="muted">Finalidade e orientação</span>
        </div>
        <div class="card-stack">
          ${renderMedicationCards('occasional')}
        </div>
      </div>
    </div>
  `;
}

function renderAgenda() {
  const sorted = [...state.data.appointments].sort((a, b) => `${a.date}T${a.time}`.localeCompare(`${b.date}T${b.time}`));

  return `
    ${renderHeader('Agenda', 'Consultas organizadas por data e compartilhadas com os cuidadores.', 'Adicionar consulta', 'appointment')}

    <section class="panel">
      <div class="panel-header">
        <h2>Todos os compromissos</h2>
        <span class="muted">${sorted.length} cadastrados</span>
      </div>
      <div class="agenda-list">
        ${renderAppointmentsList(sorted)}
      </div>
    </section>
  `;
}

function renderDocumentRows(limit) {
  const items = [...state.data.documents].sort((a, b) => b.date.localeCompare(a.date)).slice(0, limit);

  if (!items.length) {
    return '<div class="empty-box">Nenhum exame ou laudo cadastrado.</div>';
  }

  return items.map((item) => `
    <article class="row-item">
      <div class="row-main">
        <strong>${escapeHtml(item.title)}</strong>
        <span>${escapeHtml(item.type || 'Exame')} · ${escapeHtml(formatDate(item.date))}${item.status ? ` · ${escapeHtml(item.status)}` : ''}${item.notes ? `<br>${escapeHtml(item.notes)}` : ''}</span>
      </div>
      ${state.activeRole === 'admin' ? `<div class="item-actions"><button class="ghost-btn" type="button" data-action="edit" data-type="document" data-id="${item.id}">Editar</button><button class="danger-btn" type="button" data-action="delete" data-type="document" data-id="${item.id}">Remover</button></div>` : ''}
    </article>
  `).join('');
}

function renderDocuments() {
  const items = [...state.data.documents].sort((a, b) => b.date.localeCompare(a.date));

  return `
    ${renderHeader('Exames e laudos', 'Registre resultados e observações para facilitar o acompanhamento.', 'Adicionar registro', 'document')}

    <section class="panel">
      <div class="panel-header">
        <h2>Registros de saúde</h2>
        <span class="muted">${items.length} cadastrados</span>
      </div>
      <div class="row-list">
        ${items.length ? items.map((item) => `
          <article class="row-item">
            <div class="row-main">
              <strong>${escapeHtml(item.title)}</strong>
              <span>${escapeHtml(item.type || 'Exame')} · ${escapeHtml(formatDate(item.date))}${item.status ? ` · ${escapeHtml(item.status)}` : ''}${item.notes ? `<br>${escapeHtml(item.notes)}` : ''}</span>
            </div>
            ${state.activeRole === 'admin' ? `<div class="item-actions"><button class="ghost-btn" type="button" data-action="edit" data-type="document" data-id="${item.id}">Editar</button><button class="danger-btn" type="button" data-action="delete" data-type="document" data-id="${item.id}">Remover</button></div>` : ''}
          </article>
        `).join('') : '<div class="empty-box">Nenhum exame ou laudo cadastrado.</div>'}
      </div>
    </section>
  `;
}

function renderAlerts() {
  const alerts = [...state.data.alerts];

  return `
    ${renderHeader('Avisos', 'Lembretes e orientações importantes para a família.', 'Adicionar aviso', 'alert')}

    <section class="panel">
      <div class="panel-header">
        <h2>Avisos do perfil</h2>
        <span class="muted">${alerts.length} cadastrados</span>
      </div>
      <div class="row-list">
        ${alerts.length ? alerts.map((item) => `
          <article class="row-item alert-row ${item.priority === 'alta' ? 'high' : item.priority === 'baixa' ? 'low' : ''}">
            <div class="row-main">
              <strong>${escapeHtml(item.title)}</strong>
              <span>Prioridade ${escapeHtml(item.priority || 'média')}${item.date ? ` · ${escapeHtml(formatDate(item.date))}` : ''}${item.note ? `<br>${escapeHtml(item.note)}` : ''}</span>
            </div>
            <div class="item-actions">
              ${state.activeRole === 'admin' ? `<button class="ghost-btn" type="button" data-action="edit" data-type="alert" data-id="${item.id}">Editar</button><button class="danger-btn" type="button" data-action="delete" data-type="alert" data-id="${item.id}">Remover</button>` : ''}
            </div>
          </article>
        `).join('') : '<div class="empty-box">Nenhum aviso cadastrado.</div>'}
      </div>
    </section>
  `;
}

function renderTeam() {
  const caregivers = state.data.caregivers.length
    ? state.data.caregivers.map((person) => `
        <div class="person-row">
          <div class="person-meta">
            <div class="person-avatar">${escapeHtml(person.name.charAt(0).toUpperCase())}</div>
            <div>
              <strong>${escapeHtml(person.name)}</strong>
              <span>${escapeHtml(person.role || 'Cuidador da família')}</span>
            </div>
          </div>
          ${state.activeRole === 'admin' ? `<div class="item-actions"><button class="ghost-btn" type="button" data-action="edit" data-type="caregiver" data-id="${person.id}">Editar</button><button class="danger-btn" type="button" data-action="delete" data-type="caregiver" data-id="${person.id}">Remover</button></div>` : ''}
        </div>
      `).join('')
    : '<div class="empty-box">Nenhum cuidador cadastrado.</div>';

  return `
    ${renderHeader('Equipe da família', 'O administrador pode organizar o perfil e todos os registros.', 'Adicionar cuidador', 'caregiver')}

    <div class="two-column">
      <section class="panel">
        <div class="panel-header">
          <h2>Administrador da família</h2>
          <span class="tag ok">Acesso total</span>
        </div>
        <div class="scope-card">
          <div class="notice">A troca de perfil no topo serve para demonstrar a visualização de cuidador. Este protótipo ainda não tem autenticação real e a conexão com banco de dados será feita em outra etapa.</div>
        </div>
      </section>

      <section class="panel">
        <div class="panel-header">
          <h2>Cuidadores</h2>
          <span class="muted">${state.data.caregivers.length} cadastrados</span>
        </div>
        <div class="row-list">
          ${caregivers}
        </div>
      </section>
    </div>
  `;
}

function openDialog(type, id = '') {
  if (state.activeRole !== 'admin') {
    showToast('Somente o administrador pode alterar os registros.');
    return;
  }

  const config = {
    profile: {
      title: 'Perfil do idoso',
      subtitle: 'Informações importantes para o cuidado diário.',
      fields: `
        <div class="form-grid">
          <div class="field full"><label for="elder">Nome completo</label><input id="elder" name="elder" value="${escapeHtml(state.data.elder || '')}" required /></div>
          <div class="field"><label for="age">Idade</label><input id="age" name="age" value="${escapeHtml(state.data.profile.age || '')}" /></div>
          <div class="field"><label for="bloodType">Tipo sanguíneo</label><select id="bloodType" name="bloodType"><option value="">Não informado</option>${['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((item) => `<option value="${item}" ${state.data.profile.bloodType === item ? 'selected' : ''}>${item}</option>`).join('')}</select></div>
          <div class="field full"><label for="allergies">Alergias</label><textarea id="allergies" name="allergies">${escapeHtml(state.data.profile.allergies || '')}</textarea></div>
          <div class="field full"><label for="conditions">Condições importantes</label><textarea id="conditions" name="conditions">${escapeHtml(state.data.profile.conditions || '')}</textarea></div>
          <div class="field full"><label for="emergencyContact">Contato de emergência</label><input id="emergencyContact" name="emergencyContact" value="${escapeHtml(state.data.profile.emergencyContact || '')}" /></div>
          <div class="field full"><label for="notes">Observações</label><textarea id="notes" name="notes">${escapeHtml(state.data.profile.notes || '')}</textarea></div>
        </div>
      `
    },
    appointment: {
      title: 'Adicionar consulta',
      subtitle: 'Compartilhe data, horário e detalhes com a família.',
      fields: `
        <div class="form-grid">
          <div class="field full"><label for="title">Consulta ou compromisso</label><input id="title" name="title" value="${escapeHtml(id ? state.data.appointments.find((item) => item.id === id)?.title || '' : '')}" required /></div>
          <div class="field"><label for="date">Data</label><input id="date" name="date" type="date" value="${escapeHtml(id ? state.data.appointments.find((item) => item.id === id)?.date || localDateString(new Date()) : localDateString(new Date()))}" required /></div>
          <div class="field"><label for="time">Horário</label><input id="time" name="time" type="time" value="${escapeHtml(id ? state.data.appointments.find((item) => item.id === id)?.time || '09:00' : '09:00')}" required /></div>
          <div class="field"><label for="location">Local</label><input id="location" name="location" value="${escapeHtml(id ? state.data.appointments.find((item) => item.id === id)?.location || '' : '')}" /></div>
          <div class="field full"><label for="notes">Observações</label><textarea id="notes" name="notes">${escapeHtml(id ? state.data.appointments.find((item) => item.id === id)?.notes || '' : '')}</textarea></div>
        </div>
      `
    },
    medicine: {
      title: 'Cadastrar medicamento',
      subtitle: 'Organize informações sem substituir a orientação profissional.',
      fields: `
        <div class="form-grid">
          <div class="field full"><label for="name">Nome</label><input id="name" name="name" value="${escapeHtml(id ? state.data.medications.find((item) => item.id === id)?.name || '' : '')}" required /></div>
          <div class="field full"><label for="type">Tipo de uso</label><select id="type" name="type"><option value="scheduled" ${id && state.data.medications.find((item) => item.id === id)?.type === 'scheduled' ? 'selected' : 'selected'}>Programado</option><option value="occasional" ${id && state.data.medications.find((item) => item.id === id)?.type === 'occasional' ? 'selected' : ''}>Ocasional</option></select></div>
          <div class="field"><label for="dosage">Dose</label><input id="dosage" name="dosage" value="${escapeHtml(id ? state.data.medications.find((item) => item.id === id)?.dosage || '' : '')}" /></div>
          <div class="field"><label for="times">Horários</label><input id="times" name="times" value="${escapeHtml(id ? state.data.medications.find((item) => item.id === id)?.times || '' : '')}" /></div>
          <div class="field full"><label for="purpose">Para que serve?</label><input id="purpose" name="purpose" value="${escapeHtml(id ? state.data.medications.find((item) => item.id === id)?.purpose || '' : '')}" /></div>
          <div class="field full"><label for="instruction">Orientação</label><textarea id="instruction" name="instruction">${escapeHtml(id ? state.data.medications.find((item) => item.id === id)?.instruction || '' : '')}</textarea></div>
        </div>
      `
    },
    document: {
      title: 'Adicionar exame ou laudo',
      subtitle: 'Registre a data, o tipo e o status do documento.',
      fields: `
        <div class="form-grid">
          <div class="field full"><label for="title">Nome do exame ou laudo</label><input id="title" name="title" value="${escapeHtml(id ? state.data.documents.find((item) => item.id === id)?.title || '' : '')}" required /></div>
          <div class="field"><label for="type">Tipo</label><select id="type" name="type"><option value="Exame" ${id && state.data.documents.find((item) => item.id === id)?.type === 'Exame' ? 'selected' : 'selected'}>Exame</option><option value="Laudo" ${id && state.data.documents.find((item) => item.id === id)?.type === 'Laudo' ? 'selected' : ''}>Laudo</option></select></div>
          <div class="field"><label for="date">Data</label><input id="date" name="date" type="date" value="${escapeHtml(id ? state.data.documents.find((item) => item.id === id)?.date || localDateString(new Date()) : localDateString(new Date()))}" required /></div>
          <div class="field full"><label for="status">Resultado ou status</label><input id="status" name="status" value="${escapeHtml(id ? state.data.documents.find((item) => item.id === id)?.status || '' : '')}" /></div>
          <div class="field full"><label for="notes">Observações</label><textarea id="notes" name="notes">${escapeHtml(id ? state.data.documents.find((item) => item.id === id)?.notes || '' : '')}</textarea></div>
        </div>
      `
    },
    alert: {
      title: 'Adicionar aviso',
      subtitle: 'Dê visibilidade a lembretes importantes da rotina.',
      fields: `
        <div class="form-grid">
          <div class="field full"><label for="title">Aviso</label><input id="title" name="title" value="${escapeHtml(id ? state.data.alerts.find((item) => item.id === id)?.title || '' : '')}" required /></div>
          <div class="field"><label for="priority">Prioridade</label><select id="priority" name="priority"><option value="alta" ${id && state.data.alerts.find((item) => item.id === id)?.priority === 'alta' ? 'selected' : ''}>Alta</option><option value="média" ${id && state.data.alerts.find((item) => item.id === id)?.priority === 'média' ? 'selected' : 'selected'}>Média</option><option value="baixa" ${id && state.data.alerts.find((item) => item.id === id)?.priority === 'baixa' ? 'selected' : ''}>Baixa</option></select></div>
          <div class="field"><label for="date">Data</label><input id="date" name="date" type="date" value="${escapeHtml(id ? state.data.alerts.find((item) => item.id === id)?.date || '' : '')}" /></div>
          <div class="field full"><label for="note">Detalhes</label><textarea id="note" name="note">${escapeHtml(id ? state.data.alerts.find((item) => item.id === id)?.note || '' : '')}</textarea></div>
        </div>
      `
    },
    caregiver: {
      title: 'Adicionar cuidador',
      subtitle: 'Inclua uma pessoa na rede de cuidado.',
      fields: `
        <div class="form-grid">
          <div class="field full"><label for="name">Nome do cuidador</label><input id="name" name="name" value="${escapeHtml(id ? state.data.caregivers.find((item) => item.id === id)?.name || '' : '')}" required /></div>
          <div class="field full"><label for="role">Função</label><input id="role" name="role" value="${escapeHtml(id ? state.data.caregivers.find((item) => item.id === id)?.role || '' : '')}" placeholder="Ex.: Filha, cuidador, enfermeira" /></div>
        </div>
      `
    }
  };

  const dialog = document.querySelector('#record-dialog');
  const form = document.querySelector('#record-form');
  const selected = config[type];
  if (!selected) return;

  document.querySelector('#dialog-title').textContent = selected.title;
  document.querySelector('#dialog-subtitle').textContent = selected.subtitle;
  form.dataset.type = type;
  form.dataset.id = id;
  form.innerHTML = `${selected.fields}<div class="form-actions"><button type="button" class="ghost-btn" data-close-dialog>Cancelar</button><button type="submit" class="primary-btn">Salvar</button></div>`;
  dialog.showModal();
  form.querySelector('input, select, textarea')?.focus();
}

function saveForm(type, formData) {
  const values = Object.fromEntries(formData.entries());

  if (type === 'profile') {
    state.data.elder = (values.elder || '').trim();
    state.data.profile = {
      ...state.data.profile,
      age: (values.age || '').trim(),
      bloodType: (values.bloodType || '').trim(),
      allergies: (values.allergies || '').trim(),
      conditions: (values.conditions || '').trim(),
      emergencyContact: (values.emergencyContact || '').trim(),
      notes: (values.notes || '').trim()
    };
    return;
  }

  const normalized = {
    appointment: (record) => ({
      id: record.id || makeId(),
      title: (record.title || '').trim(),
      date: (record.date || '').trim(),
      time: (record.time || '').trim(),
      location: (record.location || '').trim(),
      notes: (record.notes || '').trim()
    }),
    medicine: (record) => ({
      id: record.id || makeId(),
      name: (record.name || '').trim(),
      type: record.type || 'scheduled',
      dosage: (record.dosage || '').trim(),
      times: (record.times || '').trim(),
      purpose: (record.purpose || '').trim(),
      instruction: (record.instruction || '').trim(),
      note: (record.note || '').trim()
    }),
    document: (record) => ({
      id: record.id || makeId(),
      title: (record.title || '').trim(),
      type: record.type || 'Exame',
      date: (record.date || '').trim(),
      status: (record.status || '').trim(),
      notes: (record.notes || '').trim()
    }),
    alert: (record) => ({
      id: record.id || makeId(),
      title: (record.title || '').trim(),
      priority: record.priority || 'média',
      date: (record.date || '').trim(),
      note: (record.note || '').trim()
    }),
    caregiver: (record) => ({
      id: record.id || makeId(),
      name: (record.name || '').trim(),
      role: (record.role || '').trim()
    })
  };

  const collectionMap = {
    appointment: 'appointments',
    medicine: 'medications',
    document: 'documents',
    alert: 'alerts',
    caregiver: 'caregivers'
  };

  const collection = collectionMap[type];
  const recordId = formData.get('id') || values.id;
  const nextRecord = normalized[type]({ ...values, id: recordId });

  if (recordId) {
    const index = state.data[collection].findIndex((item) => String(item.id) === String(recordId));
    if (index >= 0) {
      state.data[collection][index] = nextRecord;
      return;
    }
  }

  state.data[collection].push(nextRecord);
}

function deleteRecord(type, id) {
  const map = {
    appointment: 'appointments',
    medicine: 'medications',
    document: 'documents',
    alert: 'alerts',
    caregiver: 'caregivers'
  };

  const collection = map[type];
  if (!collection) return;

  state.data[collection] = state.data[collection].filter((item) => String(item.id) !== String(id));
  showToast('Registro removido.');
  saveData();
  renderApp();
}

function showToast(message) {
  const toast = document.querySelector('#toast');
  if (!toast) return;
  toast.textContent = message;
  toast.hidden = false;
  clearTimeout(state.toastTimer);
  state.toastTimer = setTimeout(() => {
    toast.hidden = true;
  }, 2200);
}

function bindEvents() {
  document.querySelector('#role-switch')?.addEventListener('click', () => {
    const wrapper = document.querySelector('[data-role-select]');
    if (!wrapper) return;
    wrapper.classList.toggle('open');
  });

  document.querySelectorAll('[data-role-option]').forEach((button) => {
    button.addEventListener('click', () => {
      const value = button.dataset.roleOption;
      state.activeRole = value;
      document.querySelector('[data-role-select]')?.classList.remove('open');
      renderApp();
    });
  });

  document.addEventListener('click', (event) => {
    const wrapper = document.querySelector('[data-role-select]');
    if (!wrapper) return;
    if (!wrapper.contains(event.target)) {
      wrapper.classList.remove('open');
    }
  });

  document.querySelectorAll('[data-view]').forEach((button) => {
    button.addEventListener('click', () => {
      const view = button.dataset.view;
      if (view) {
        state.activeView = view;
        renderApp();
      }
    });
  });

  document.querySelectorAll('[data-action]').forEach((button) => {
    button.addEventListener('click', () => {
      const { action, type, id } = button.dataset;

      if (action === 'previous-month') {
        state.shownMonth = new Date(state.shownMonth.getFullYear(), state.shownMonth.getMonth() - 1, 1);
        renderApp();
        return;
      }

      if (action === 'next-month') {
        state.shownMonth = new Date(state.shownMonth.getFullYear(), state.shownMonth.getMonth() + 1, 1);
        renderApp();
        return;
      }

      if (action === 'edit' || action === 'appointment' || action === 'medicine' || action === 'document' || action === 'alert' || action === 'caregiver' || action === 'profile') {
        if (action === 'edit') {
          openDialog(type, id);
        } else {
          openDialog(action);
        }
        return;
      }

      if (action === 'delete') {
        deleteRecord(type, id);
      }
    });
  });

  document.querySelector('#login-form')?.addEventListener('submit', (event) => {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);
    const email = String(formData.get('email') || '').trim();
    const password = String(formData.get('password') || '').trim();

    if (email === 'admin@longevus.com' && password === 'longevus123') {
      state.authenticated = true;
      renderApp();
      showToast('Login realizado com sucesso.');
      return;
    }

    showToast('Credenciais inválidas.');
  });

  document.querySelector('[data-action="logout"]')?.addEventListener('click', () => {
    state.authenticated = false;
    renderApp();
  });

  document.querySelector('#login-form')?.addEventListener('click', (event) => {
    if (event.target.matches('.link-btn')) {
      showToast('Recuperação de senha em desenvolvimento.');
    }
  });
}

renderApp();
