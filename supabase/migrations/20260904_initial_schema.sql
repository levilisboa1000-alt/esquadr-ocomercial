-- ============================================================================
-- ESQUADRÃO COMERCIAL - DATABASE SCHEMA & MIGRATIONS
-- Supabase / PostgreSQL 15+
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. ENUMS
CREATE TYPE user_role AS ENUM ('admin', 'supervisor', 'operator');

CREATE TYPE lead_status AS ENUM (
    'NOVO',
    'DISTRIBUIDO',
    'EM_ATENDIMENTO',
    'LIGACAO_REALIZADA',
    'CAIXA_POSTAL',
    'AGENDADO',
    'CONFIRMADO',
    'ATENDIDO',
    'NAO_INTERESSADO',
    'RETORNAR_PARA_FILA',
    'FINALIZADO',
    'CANCELADO'
);

CREATE TYPE lead_priority AS ENUM ('baixa', 'normal', 'alta', 'urgente');

CREATE TYPE call_result AS ENUM (
    'atendeu',
    'nao_atendeu',
    'caixa_postal',
    'numero_invalido',
    'retornar_depois',
    'interessado',
    'nao_interessado',
    'agendamento'
);

CREATE TYPE appointment_status AS ENUM (
    'AGENDADO',
    '24_HORAS',
    'CONFIRMADO',
    'EM_ATENDIMENTO',
    'ATENDIDO',
    'NAO_COMPARECEU',
    'CANCELADO',
    'RETORNOU_PARA_LEAD',
    'FINALIZADO'
);

-- 2. TEAMS TABLE
CREATE TABLE IF NOT EXISTS teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    supervisor_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. PROFILES TABLE (Linked with Supabase auth.users)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    role user_role NOT NULL DEFAULT 'operator',
    phone VARCHAR(30),
    avatar_url TEXT,
    is_online BOOLEAN NOT NULL DEFAULT FALSE,
    team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    daily_lead_goal INT NOT NULL DEFAULT 30,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add supervisor foreign key to teams
ALTER TABLE teams 
    DROP CONSTRAINT IF EXISTS fk_teams_supervisor;
ALTER TABLE teams 
    ADD CONSTRAINT fk_teams_supervisor 
    FOREIGN KEY (supervisor_id) REFERENCES profiles(id) ON DELETE SET NULL;

-- 4. SYSTEM SETTINGS TABLE
CREATE TABLE IF NOT EXISTS system_settings (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert default system settings
INSERT INTO system_settings (key, value, description)
VALUES 
    ('voicemail_return_minutes', '30'::jsonb, 'Tempo em minutos para um lead de caixa postal retornar para a fila'),
    ('distribution_algorithm', '"ROUND_ROBIN"'::jsonb, 'Algoritmo de distribuicao de leads: ROUND_ROBIN, LOAD_BALANCE, PRIORITY'),
    ('max_daily_leads_per_operator', '50'::jsonb, 'Limite de leads diarios distribuidos por operador')
ON CONFLICT (key) DO NOTHING;

-- 5. LEADS TABLE
CREATE TABLE IF NOT EXISTS leads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    city VARCHAR(100) NOT NULL DEFAULT '',
    state VARCHAR(10) NOT NULL DEFAULT '',
    interest VARCHAR(150) NOT NULL DEFAULT '',
    property_value NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    source VARCHAR(100) NOT NULL DEFAULT 'Outros',
    notes TEXT,
    status lead_status NOT NULL DEFAULT 'NOVO',
    priority lead_priority NOT NULL DEFAULT 'normal',
    assigned_operator_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    attempt_count INT NOT NULL DEFAULT 0,
    last_contact_at TIMESTAMPTZ,
    next_action_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_assigned_operator ON leads(assigned_operator_id);
CREATE INDEX IF NOT EXISTS idx_leads_phone ON leads(phone);
CREATE INDEX IF NOT EXISTS idx_leads_next_action ON leads(next_action_at);
CREATE INDEX IF NOT EXISTS idx_leads_created_at ON leads(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_leads_queue_search ON leads(status, priority, attempt_count, created_at)
    WHERE status IN ('NOVO', 'RETORNAR_PARA_FILA');

-- 6. LEAD HISTORY TABLE
CREATE TABLE IF NOT EXISTS lead_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    user_name VARCHAR(150),
    action VARCHAR(100) NOT NULL,
    old_status lead_status,
    new_status lead_status,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lead_history_lead_id ON lead_history(lead_id);
CREATE INDEX IF NOT EXISTS idx_lead_history_created_at ON lead_history(created_at DESC);

-- 7. CALLS TABLE
CREATE TABLE IF NOT EXISTS calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    operator_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    attempt_number INT NOT NULL DEFAULT 1,
    result call_result NOT NULL,
    notes TEXT,
    duration_seconds INT NOT NULL DEFAULT 0,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_calls_lead_id ON calls(lead_id);
CREATE INDEX IF NOT EXISTS idx_calls_operator_id ON calls(operator_id);
CREATE INDEX IF NOT EXISTS idx_calls_created_at ON calls(created_at DESC);

-- 8. APPOINTMENTS TABLE
CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    operator_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    scheduled_at TIMESTAMPTZ NOT NULL,
    status appointment_status NOT NULL DEFAULT 'AGENDADO',
    notes TEXT,
    google_calendar_event_id VARCHAR(255),
    google_calendar_html_link TEXT,
    reminder_sent_24h BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_appointments_scheduled_at ON appointments(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_appointments_operator_id ON appointments(operator_id);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);

-- 9. AUDIT LOGS TABLE
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    user_name VARCHAR(150) NOT NULL DEFAULT 'Sistema',
    role user_role,
    action VARCHAR(150) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id VARCHAR(100),
    old_value JSONB,
    new_value JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id);

-- 10. GOOGLE CALENDAR ACCOUNTS TABLE
CREATE TABLE IF NOT EXISTS google_calendar_accounts (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    access_token TEXT NOT NULL,
    refresh_token TEXT,
    token_expiry TIMESTAMPTZ,
    calendar_id VARCHAR(255) DEFAULT 'primary',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- STORED PROCEDURES & DATABASE FUNCTIONS
-- ============================================================================

-- A. Lead Distribution Function (Atomically claim leads for an operator)
CREATE OR REPLACE FUNCTION distribute_leads_to_operator(
    p_operator_id UUID,
    p_limit INT DEFAULT 10
)
RETURNS SETOF leads
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_operator_role user_role;
    v_is_online BOOLEAN;
BEGIN
    -- Verify operator eligibility
    SELECT role, is_online INTO v_operator_role, v_is_online
    FROM profiles
    WHERE id = p_operator_id;

    IF v_operator_role IS NULL THEN
        RAISE EXCEPTION 'Operador não encontrado';
    END IF;

    -- Return locked and updated leads
    RETURN QUERY
    WITH candidate_leads AS (
        SELECT id
        FROM leads
        WHERE (status IN ('NOVO', 'RETORNAR_PARA_FILA'))
          AND (assigned_operator_id IS NULL OR assigned_operator_id = p_operator_id)
        ORDER BY 
            CASE priority
                WHEN 'urgente' THEN 1
                WHEN 'alta' THEN 2
                WHEN 'normal' THEN 3
                WHEN 'baixa' THEN 4
            END ASC,
            attempt_count ASC,
            created_at ASC
        LIMIT p_limit
        FOR UPDATE SKIP LOCKED
    ),
    updated_leads AS (
        UPDATE leads l
        SET 
            assigned_operator_id = p_operator_id,
            status = 'DISTRIBUIDO',
            updated_at = NOW()
        FROM candidate_leads c
        WHERE l.id = c.id
        RETURNING l.*
    )
    SELECT * FROM updated_leads;
END;
$$;

-- B. Reconcile Voicemail leads (Return leads to central queue after timeout)
CREATE OR REPLACE FUNCTION reconcile_voicemail_leads()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INT := 0;
    r_lead RECORD;
BEGIN
    -- Find leads in CAIXA_POSTAL whose next_action_at has arrived
    FOR r_lead IN 
        SELECT id, name, assigned_operator_id
        FROM leads
        WHERE status = 'CAIXA_POSTAL'
          AND next_action_at IS NOT NULL
          AND next_action_at <= NOW()
        FOR UPDATE SKIP LOCKED
    LOOP
        -- Update lead back to queue
        UPDATE leads
        SET 
            status = 'RETORNAR_PARA_FILA',
            assigned_operator_id = NULL,
            updated_at = NOW()
        WHERE id = r_lead.id;

        -- Record history
        INSERT INTO lead_history (
            lead_id, 
            action, 
            old_status, 
            new_status, 
            notes, 
            created_at
        ) VALUES (
            r_lead.id,
            'Retornou para a fila central automaticamente',
            'CAIXA_POSTAL',
            'RETORNAR_PARA_FILA',
            'Prazo de caixa postal expirado no backend',
            NOW()
        );

        v_count := v_count + 1;
    END LOOP;

    RETURN v_count;
END;
$$;

-- C. Trigger: Automatic Profile creation on Auth Sign Up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role, is_online)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'operator'),
        FALSE
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE google_calendar_accounts ENABLE ROW LEVEL SECURITY;

-- Helper function to get current user role
CREATE OR REPLACE FUNCTION get_auth_user_role()
RETURNS user_role
LANGUAGE sql
STABLE
AS $$
    SELECT role FROM profiles WHERE id = auth.uid();
$$;

-- Profiles: Users can view all profiles, but edit only their own (or admin/supervisor)
CREATE POLICY "profiles_select" ON profiles 
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "profiles_update" ON profiles 
    FOR UPDATE TO authenticated 
    USING (id = auth.uid() OR get_auth_user_role() IN ('admin', 'supervisor'));

-- Leads Policies:
CREATE POLICY "leads_admin_all" ON leads
    FOR ALL TO authenticated
    USING (get_auth_user_role() IN ('admin', 'supervisor'));

CREATE POLICY "leads_operator_select" ON leads
    FOR SELECT TO authenticated
    USING (
        assigned_operator_id = auth.uid() 
        OR (assigned_operator_id IS NULL AND status IN ('NOVO', 'RETORNAR_PARA_FILA'))
    );

CREATE POLICY "leads_operator_update" ON leads
    FOR UPDATE TO authenticated
    USING (assigned_operator_id = auth.uid())
    WITH CHECK (assigned_operator_id = auth.uid());

-- Lead History:
CREATE POLICY "lead_history_select" ON lead_history
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "lead_history_insert" ON lead_history
    FOR INSERT TO authenticated WITH CHECK (true);

-- Calls Policies:
CREATE POLICY "calls_admin_all" ON calls
    FOR ALL TO authenticated
    USING (get_auth_user_role() IN ('admin', 'supervisor'));

CREATE POLICY "calls_operator_insert_select" ON calls
    FOR ALL TO authenticated
    USING (operator_id = auth.uid());

-- Appointments Policies:
CREATE POLICY "appointments_all" ON appointments
    FOR ALL TO authenticated
    USING (
        get_auth_user_role() IN ('admin', 'supervisor')
        OR operator_id = auth.uid()
    );

-- Audit Logs Policies:
CREATE POLICY "audit_logs_select" ON audit_logs
    FOR SELECT TO authenticated
    USING (get_auth_user_role() IN ('admin', 'supervisor'));

CREATE POLICY "audit_logs_insert" ON audit_logs
    FOR INSERT TO authenticated WITH CHECK (true);

-- System Settings: Read for all authenticated, write only for admin
CREATE POLICY "settings_select" ON system_settings
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "settings_modify" ON system_settings
    FOR ALL TO authenticated
    USING (get_auth_user_role() = 'admin');

-- Google Calendar Accounts: User manages own credentials
CREATE POLICY "google_calendar_own" ON google_calendar_accounts
    FOR ALL TO authenticated
    USING (user_id = auth.uid());
