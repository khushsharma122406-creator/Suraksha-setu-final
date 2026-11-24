-- ==============================================================================
-- SURAKSHA SETU — ENTERPRISE SUPABASE POSTGRESQL SCHEMA
-- Target: Rajasthan Police Cyber Security Hackathon (Cyber Fraud / Phishing / APKs)
-- Version: 2.0.0 (Production / Staging DDL)
-- Features: 12 Normalized Relational Tables, RLS Policies, Indexes, Triggers
-- ==============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Clean existing schema if necessary (controlled recreation)
-- DROP SCHEMA IF EXISTS public CASCADE;
-- CREATE SCHEMA public;

-- ==============================================================================
-- 1. TABLE: profiles
-- User profiles extending auth.users with police and citizen roles
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(32) NOT NULL CHECK (role IN ('citizen', 'police_officer', 'admin')),
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(32),
    badge_number VARCHAR(64),
    police_station VARCHAR(255),
    department VARCHAR(255),
    is_authorized BOOLEAN DEFAULT false,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 2. TABLE: citizen_reports
-- Citizen-submitted scans, suspicious URLs, SMS lures, and scam complaints
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.citizen_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id VARCHAR(64) UNIQUE NOT NULL, -- e.g. CR-2026-1049
    citizen_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    scan_type VARCHAR(32) NOT NULL CHECK (scan_type IN ('url', 'message', 'apk', 'app_store', 'website')),
    submitted_content TEXT NOT NULL,
    risk_level VARCHAR(16) NOT NULL CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    risk_score INTEGER NOT NULL CHECK (risk_score >= 0 AND risk_score <= 100),
    detected_indicators JSONB DEFAULT '[]'::jsonb,
    raw_analysis_result JSONB DEFAULT '{}'::jsonb,
    status VARCHAR(32) DEFAULT 'PENDING_REVIEW' CHECK (status IN ('PENDING_REVIEW', 'UNDER_INVESTIGATION', 'RESOLVED', 'DISMISSED')),
    contact_phone VARCHAR(32),
    contact_email VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 3. TABLE: police_cases
-- Formal cybercrime investigation dockets and case records
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.police_cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id VARCHAR(64) UNIQUE NOT NULL, -- e.g. SS-2026-1049
    source_report_id UUID REFERENCES public.citizen_reports(id) ON DELETE SET NULL,
    title VARCHAR(512) NOT NULL,
    category VARCHAR(128) NOT NULL, -- e.g. Phishing, Extortion, Trojan APK
    priority VARCHAR(16) NOT NULL CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    status VARCHAR(32) NOT NULL DEFAULT 'NEW' CHECK (status IN ('NEW', 'UNDER_REVIEW', 'ASSIGNED', 'INVESTIGATING', 'ESCALATED', 'RESOLVED', 'CLOSED')),
    assigned_officer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    assigned_station VARCHAR(255) NOT NULL,
    incident_timestamp TIMESTAMPTZ DEFAULT NOW(),
    evidence_hash VARCHAR(64), -- SHA-256 integrity hash
    summary TEXT,
    explanation TEXT,
    recommendations JSONB DEFAULT '[]'::jsonb,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    loss_amount_inr NUMERIC(14, 2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 4. TABLE: case_assignments
-- Audit trail of officer assignments and delegation handoffs
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.case_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES public.police_cases(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    assigned_to UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    previous_officer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    notes TEXT,
    assigned_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 5. TABLE: threat_analyses
-- Deep multi-format threat scans executed by citizens or investigators
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.threat_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    target_type VARCHAR(32) NOT NULL CHECK (target_type IN ('URL', 'MESSAGE', 'APK', 'DOMAIN', 'IP')),
    target_value TEXT NOT NULL,
    risk_score INTEGER NOT NULL CHECK (risk_score >= 0 AND risk_score <= 100),
    risk_level VARCHAR(16) NOT NULL CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    findings JSONB DEFAULT '[]'::jsonb,
    heuristics_triggered JSONB DEFAULT '[]'::jsonb,
    external_intel JSONB DEFAULT '{}'::jsonb,
    sha256_fingerprint VARCHAR(64),
    analyzed_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 6. TABLE: threat_indicators
-- Normalized Indicators of Compromise (IOCs) across all investigations
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.threat_indicators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    indicator_type VARCHAR(32) NOT NULL CHECK (indicator_type IN ('PHONE', 'UPI', 'DOMAIN', 'IP', 'URL_HASH', 'APK_HASH', 'BANK_ACCOUNT')),
    indicator_value VARCHAR(512) NOT NULL,
    risk_weight INTEGER DEFAULT 10,
    times_observed INTEGER DEFAULT 1,
    first_seen TIMESTAMPTZ DEFAULT NOW(),
    last_seen TIMESTAMPTZ DEFAULT NOW(),
    threat_tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    associated_syndicate VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    CONSTRAINT uq_indicator_type_value UNIQUE (indicator_type, indicator_value)
);

-- ==============================================================================
-- 7. TABLE: report_indicators
-- Junction table mapping reports & cases to individual IOCs for graph correlation
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.report_indicators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    indicator_id UUID NOT NULL REFERENCES public.threat_indicators(id) ON DELETE CASCADE,
    report_id UUID REFERENCES public.citizen_reports(id) ON DELETE CASCADE,
    case_id UUID REFERENCES public.police_cases(id) ON DELETE CASCADE,
    analysis_id UUID REFERENCES public.threat_analyses(id) ON DELETE CASCADE,
    context_role VARCHAR(64) DEFAULT 'vector', -- 'vector', 'mule', 'c2_host', 'caller'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 8. TABLE: evidence_files
-- Section 65B compliant digital evidence items with SHA-256 chain of custody
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.evidence_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES public.police_cases(id) ON DELETE CASCADE,
    uploader_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    file_name VARCHAR(255) NOT NULL,
    file_type VARCHAR(128) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    storage_path TEXT NOT NULL,
    sha256_hash VARCHAR(64) NOT NULL,
    custody_chain JSONB DEFAULT '[]'::jsonb,
    is_tamper_verified BOOLEAN DEFAULT true,
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 9. TABLE: investigation_notes
-- Confidential case notes authored by investigators and prosecutors
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.investigation_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES public.police_cases(id) ON DELETE CASCADE,
    officer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    note_text TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 10. TABLE: audit_logs
-- Immutable tamper-proof access and action audit trail for LEA compliance
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action VARCHAR(128) NOT NULL,
    entity_type VARCHAR(64) NOT NULL,
    entity_id VARCHAR(128) NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    details JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 11. TABLE: intelligence_sources
-- Status and metrics for external threat intel feeds (VT, URLhaus, AbuseIPDB)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.intelligence_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_name VARCHAR(64) UNIQUE NOT NULL,
    query_count INTEGER DEFAULT 0,
    last_queried_at TIMESTAMPTZ,
    status VARCHAR(32) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'RATE_LIMITED', 'DOWN', 'UNCONFIGURED')),
    config JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 12. TABLE: api_usage_logs
-- Observability and rate limit tracking for external intelligence APIs
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.api_usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id UUID REFERENCES public.intelligence_sources(id) ON DELETE CASCADE,
    endpoint VARCHAR(255) NOT NULL,
    status_code INTEGER NOT NULL,
    response_time_ms INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- HIGH-PERFORMANCE INDEXES
-- Optimized for real-time triage, IOC search, and graph correlations
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_citizen_reports_citizen ON public.citizen_reports(citizen_id);
CREATE INDEX IF NOT EXISTS idx_citizen_reports_status ON public.citizen_reports(status);
CREATE INDEX IF NOT EXISTS idx_citizen_reports_risk ON public.citizen_reports(risk_level);
CREATE INDEX IF NOT EXISTS idx_citizen_reports_report_id ON public.citizen_reports(report_id);

CREATE INDEX IF NOT EXISTS idx_police_cases_case_id ON public.police_cases(case_id);
CREATE INDEX IF NOT EXISTS idx_police_cases_status ON public.police_cases(status);
CREATE INDEX IF NOT EXISTS idx_police_cases_priority ON public.police_cases(priority);
CREATE INDEX IF NOT EXISTS idx_police_cases_assigned_officer ON public.police_cases(assigned_officer_id);
CREATE INDEX IF NOT EXISTS idx_police_cases_created ON public.police_cases(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_threat_indicators_type_val ON public.threat_indicators(indicator_type, indicator_value);
CREATE INDEX IF NOT EXISTS idx_threat_indicators_times ON public.threat_indicators(times_observed DESC);
CREATE INDEX IF NOT EXISTS idx_report_indicators_indicator ON public.report_indicators(indicator_id);
CREATE INDEX IF NOT EXISTS idx_report_indicators_case ON public.report_indicators(case_id);

CREATE INDEX IF NOT EXISTS idx_evidence_files_case ON public.evidence_files(case_id);
CREATE INDEX IF NOT EXISTS idx_evidence_files_hash ON public.evidence_files(sha256_hash);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON public.audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON public.audit_logs(created_at DESC);

-- ==============================================================================
-- AUTOMATED TRIGGERS & PROCEDURES
-- ==============================================================================

-- Trigger to keep updated_at in sync
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_citizen_reports_updated_at
BEFORE UPDATE ON public.citizen_reports
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_police_cases_updated_at
BEFORE UPDATE ON public.police_cases
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Trigger to increment indicator times_observed on repeated insertion
CREATE OR REPLACE FUNCTION public.upsert_threat_indicator(
    p_type VARCHAR,
    p_value VARCHAR,
    p_risk_weight INTEGER,
    p_tag VARCHAR
)
RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO public.threat_indicators (indicator_type, indicator_value, risk_weight, times_observed, first_seen, last_seen, threat_tags)
    VALUES (p_type, p_value, p_risk_weight, 1, NOW(), NOW(), ARRAY[p_tag])
    ON CONFLICT (indicator_type, indicator_value)
    DO UPDATE SET
        times_observed = public.threat_indicators.times_observed + 1,
        last_seen = NOW(),
        threat_tags = array_cat(public.threat_indicators.threat_tags, ARRAY[p_tag])
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- Zero-Trust Enforcement: Segregates Citizen, Police, and Admin Access
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.citizen_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.police_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.threat_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.threat_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evidence_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investigation_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.intelligence_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_usage_logs ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can view their own profile; Officers/Admins can view police profiles
CREATE POLICY "Users can read own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Officers can read officer profiles" ON public.profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('police_officer', 'admin')
        )
    );

-- Citizen Reports: Citizens read their own; Police view all
CREATE POLICY "Citizens can insert own reports" ON public.citizen_reports
    FOR INSERT WITH CHECK (auth.uid() = citizen_id);

CREATE POLICY "Citizens can view own reports" ON public.citizen_reports
    FOR SELECT USING (auth.uid() = citizen_id);

CREATE POLICY "Police view all citizen reports" ON public.citizen_reports
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('police_officer', 'admin')
        )
    );

-- Police Cases: ONLY Officers and Admins can view/update
CREATE POLICY "Police view and manage cases" ON public.police_cases
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('police_officer', 'admin')
        )
    );

-- Evidence & Notes: Police only
CREATE POLICY "Police access evidence files" ON public.evidence_files
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('police_officer', 'admin')
        )
    );

CREATE POLICY "Police access investigation notes" ON public.investigation_notes
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('police_officer', 'admin')
        )
    );

-- Indicators & Threat Analyses: Citizens can insert scan analyses; Police can view all
CREATE POLICY "Anyone can insert threat analyses" ON public.threat_analyses
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Police view all threat analyses" ON public.threat_analyses
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('police_officer', 'admin')
        )
    );

CREATE POLICY "Police access threat indicators" ON public.threat_indicators
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('police_officer', 'admin')
        )
    );

-- Audit Logs: Admin only for viewing, system triggers for insertion
CREATE POLICY "Admins can view audit logs" ON public.audit_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ==============================================================================
-- INITIAL SEED DATA FOR DEMONSTRATION & HACKATHON EVALUATION
-- ==============================================================================
INSERT INTO public.intelligence_sources (source_name, status, config)
VALUES 
    ('VirusTotal', 'ACTIVE', '{"api_version": "v3", "daily_quota": 500}'::jsonb),
    ('URLhaus', 'ACTIVE', '{"endpoint": "https://urlhaus-api.abuse.ch/v1/"}'::jsonb),
    ('AbuseIPDB', 'ACTIVE', '{"api_version": "v2", "confidence_minimum": 25}'::jsonb),
    ('GoogleSafeBrowsing', 'ACTIVE', '{"api_version": "v4"}'::jsonb)
ON CONFLICT (source_name) DO NOTHING;
