# 🚀 Esquadrão Comercial

Plataforma operacional de **Telemarketing de Alta Performance** para distribuição centralizada, tratamento ágil e acompanhamento de leads em tempo real.

O sistema substitui abordagens de CRMs genéricos por uma experiência ultra-rápida baseada em **Swipe Cards (Tinder de Leads)** para operadores e uma **Central de Operações** completa para supervisores e administradores, construído em Flutter e conectado ao Supabase (PostgreSQL centralizado com Row Level Security e anti-colisão de concorrência).

---

## 📱 Ambientes da Aplicação

### 1. Operador (Tinder de Leads)
- **Interface de Foco Total:** 1 card por vez em pilha física com renderização a 60 FPS.
- **Interação por Gestos Físicos:**
  - **DIREITA (Verde):** 📞 **LIGAR** — Dispara o discador nativo (`tel:+55...`) via `url_launcher`. Ao retornar ao aplicativo, o contexto do lead é mantido e abre o diálogo de feedback pós-chamada para registrar o resultado (Atendeu, Não Atendeu, Caixa Postal, etc.).
  - **CIMA (Azul):** 📅 **AGENDAR** — Abre o fluxo de agendamento com data, horário, responsável e observações, sincronizando com a **Google Calendar API (OAuth 2.0)** e gravando o `google_calendar_event_id`.
  - **ESQUERDA (Âmbar):** 📭 **CAIXA POSTAL** — Aplica a regra de expiração de **30 minutos** diretamente no banco de dados. O lead sai imediatamente da fila do operador e retorna à Fila Central automaticamente após o intervalo configurado.
  - **BAIXO (Vermelho):** ✕ **NÃO INTERESSADO** — Registra a recusa, atualiza tentativas e arquiva sem deletar os dados.
- **Acessibilidade:** 4 botões físicos na base com Semantics para leitores de tela e toque direto.
- **Gamificação Profissional:** Barra superior com progresso da meta diária (ex: 17/30 processados), contador de fila e indicadores.

### 2. Administrativo (Central de Operações)
Navegação inferior estilo WhatsApp no iOS com 5 abas em **Liquid Glass**:
1. **Início (Dashboard):** Métricas em tempo real vindas do PostgreSQL (leads ativos, ligações hoje, agendamentos, conversão, operadores online), gráficos `fl_chart` e feed de auditoria.
2. **Leads:** Gestão completa com busca instantânea, filtros múltiplos (por status, operador, cidade, origem), modal de detalhes, devolução para fila e exclusão.
3. **Agenda:** Calendário operacional com visualizações (Dia, Semana e Lista), status de atendimento (`AGENDADO`, `24_HORAS`, `CONFIRMADO`, `ATENDIDO`, `CANCELADO`) e indicador de sincronização Google Calendar.
4. **Equipe:** Gestão de operadores e supervisores, status online/offline em tempo real, produtividade individual (leads recebidos, chamadas, conversão %) e alteração de papéis.
5. **Mais:** Configurações de negócio (tempo de retorno da Caixa Postal em minutos), conexão OAuth com Google Calendar, e logout seguro.

---

## 🛠️ Tecnologias e Arquitetura

- **Frontend:** Dart 3.x, Flutter 3.x (Android, iOS, Web, Desktop).
- **Design System:** Liquid Glass (Dark mode, Slate 900 a Indigo 950, BackdropFilter blur, bordas e reflexos translúcidos).
- **State Management:** Provider com arquitetura reativa desacoplada.
- **Backend Central:** Supabase (PostgreSQL 15+, Supabase Auth, Row Level Security).
- **Fila Central Anti-Colisão:** Stored Procedure PostgreSQL `distribute_leads_to_operator` utilizando `SELECT ... FOR UPDATE SKIP LOCKED`, garantindo que operadores simultâneos nunca recebam o mesmo lead.
- **Regra de 30 Minutos de Caixa Postal:** Procedimento `reconcile_voicemail_leads()` executado no backend e reforçado por polling leve e gatilhos de consulta.
- **Integração Telefônica:** `url_launcher` com `tel:`, sanitização de DDD e formato brasileiro.
- **Google Calendar:** `google_sign_in` e `googleapis` (Calendar API v3).

---

## 📂 Estrutura Modular do Projeto

```
lib/
├── core/
│   ├── config/              # EnvConfig (.env loader e validadores)
│   ├── constants/           # AppColors, AppEnums, AppDimensions
│   ├── errors/              # Hierarquia de Falhas (Failures)
│   ├── theme/               # LiquidTheme Material 3 & decorações de vidro
│   └── utils/               # Formatters, PhoneUtils, Validators
├── models/
│   ├── appointment_model.dart
│   ├── audit_log_model.dart
│   ├── call_model.dart
│   ├── goal_model.dart
│   ├── lead_history_model.dart
│   ├── lead_model.dart
│   ├── system_settings_model.dart
│   ├── team_model.dart
│   └── user_model.dart
├── services/
│   ├── audit/               # AuditService (logs de ações no banco)
│   ├── auth/                # SupabaseAuthService (login, sessão, status online)
│   ├── calendar/            # GoogleCalendarService (OAuth 2.0 & Calendar API)
│   ├── import/              # LeadImportService (CSV parsing, duplicados, fila)
│   ├── lead_distribution/   # LeadDistributionService (anti-colisão SKIP LOCKED)
│   ├── phone_call/          # PhoneCallService (tel: launcher e contexto)
│   └── voicemail/           # VoicemailSchedulerService (regra de 30 min)
├── repositories/
│   ├── appointment_repository.dart
│   ├── call_repository.dart
│   ├── lead_repository.dart
│   ├── settings_repository.dart
│   └── user_repository.dart
├── features/
│   ├── auth/screens/        # LoginScreen (autenticação real, sign-up e recuperação)
│   ├── dashboard/           # AdminOperationsCenter & AdminHomeTab
│   ├── leads/tabs/          # AdminLeadsTab
│   ├── import/screens/      # LeadImportModal
│   ├── calendar/tabs/       # AdminCalendarTab
│   ├── team/tabs/           # AdminTeamTab
│   ├── settings/tabs/       # AdminMoreTab
│   └── operator/            # SwipeCard, CallFeedbackDialog, ScheduleModal, OperatorDeckScreen
├── shared/widgets/          # GlassContainer, LiquidBackground, ActionButton, GlassTextField, GlassBadge
└── main.dart                # Inicialização e roteamento por Role
```

---

## ⚙️ Configuração Passo a Passo

### 1. Pré-requisitos
- Flutter SDK (versão `>= 3.24.0`)
- Dart SDK (versão `>= 3.5.0`)
- Projeto no [Supabase](https://supabase.com)
- Projeto no [Google Cloud Console](https://console.cloud.google.com) (para sincronização com Google Calendar)

### 2. Configuração do Backend (Supabase)
1. Acesse o **SQL Editor** do seu projeto no Supabase Dashboard.
2. Abra o arquivo de migração [`supabase/migrations/20260904_initial_schema.sql`](supabase/migrations/20260904_initial_schema.sql).
3. Cole e execute o script SQL completo.
   - Isso criará todas as tabelas (`profiles`, `leads`, `calls`, `appointments`, `audit_logs`, `teams`, `system_settings`, `google_calendar_accounts`), índices, triggers e funções atômicas de fila (`distribute_leads_to_operator` e `reconcile_voicemail_leads`).
4. (Opcional - Recomendado) No Supabase, habilite a extensão `pg_cron` e agende a reconciliação automática de Caixa Postal:
   ```sql
   SELECT cron.schedule('reconcile-voicemail', '*/1 * * * *', 'SELECT reconcile_voicemail_leads();');
   ```

### 3. Variáveis de Ambiente (`.env`)
Copie o arquivo `.env.example` para `.env`:
```bash
cp .env.example .env
```
Preencha as variáveis com suas credenciais reais:
```env
# Supabase (Project Settings -> API)
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-anon-aqui

# Google Calendar (Google Cloud Console -> Credentials -> OAuth Client IDs)
GOOGLE_CLIENT_ID_WEB=seu-client-id-web.apps.googleusercontent.com
GOOGLE_CLIENT_ID_ANDROID=seu-client-id-android.apps.googleusercontent.com
GOOGLE_CLIENT_ID_IOS=seu-client-id-ios.apps.googleusercontent.com

# Regras de Negócio
DEFAULT_VOICEMAIL_RETURN_MINUTES=30
DEFAULT_DAILY_LEAD_GOAL=30
```

### 4. Configuração do Google Cloud Project (Google Calendar)
1. No **Google Cloud Console**, ative a **Google Calendar API**.
2. Configure a **OAuth Consent Screen** (adicionando os escopos `email` e `https://www.googleapis.com/auth/calendar.events`).
3. Em **Credentials**, crie credenciais OAuth 2.0:
   - Para Web: Adicione as URIs autorizadas de redirecionamento.
   - Para Android: Forneça o nome do pacote `com.esquadraocomercial.esquadrao_comercial` e o SHA-1 da sua chave de assinatura.
   - Para iOS: Forneça o Bundle Identifier `com.esquadraocomercial.esquadraoComercial`.

---

## 🧪 Testes Automatizados

O projeto conta com suíte completa de testes unitários e de widgets.

Execute os testes com:
```bash
flutter test
```

Para análise de código e garantia de zero problemas:
```bash
flutter analyze
```

---

## 📦 Compilação e Deploy (Build)

### Android
```bash
# APK de Release
flutter build apk --release

# App Bundle para publicação na Google Play Store
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```
Os artefatos compilados para Web estarão disponíveis em `build/web/` prontos para deploy no Vercel, Netlify, Firebase Hosting ou Cloudflare Pages.

---

## 📄 Licença
Projeto confidencial desenvolvido para a operação **Esquadrão Comercial**.
