-- ===========================================
-- HMIS Database Schema - PostgreSQL
-- Hankes Music Intelligence System
-- ===========================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===========================================
-- UTILISATEURS
-- ===========================================
CREATE TABLE IF NOT EXISTS utilisateurs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    telephone VARCHAR(20),
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'etablissement', 'partenaire')),
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_utilisateurs_email ON utilisateurs(email);
CREATE INDEX idx_utilisateurs_role ON utilisateurs(role);

-- ===========================================
-- ETABLISSEMENTS
-- ===========================================
CREATE TABLE IF NOT EXISTS etablissements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    utilisateur_id UUID REFERENCES utilisateurs(id) ON DELETE SET NULL,
    nom VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('bar', 'maquis', 'cave', 'boite_nuit', 'autre')),
    adresse VARCHAR(500) NOT NULL,
    ville VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    telephone VARCHAR(20),
    capacite INTEGER,
    horaires_ouverture JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_etablissements_ville ON etablissements(ville);
CREATE INDEX idx_etablissements_type ON etablissements(type);
CREATE INDEX idx_etablissements_utilisateur ON etablissements(utilisateur_id);

-- ===========================================
-- APPAREILS (DEVICES)
-- ===========================================
CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    utilisateur_id UUID REFERENCES utilisateurs(id) ON DELETE CASCADE,
    etablissement_id UUID REFERENCES etablissements(id) ON DELETE CASCADE,
    device_name VARCHAR(100),
    device_model VARCHAR(100),
    os VARCHAR(50),
    os_version VARCHAR(50),
    app_version VARCHAR(20),
    push_token VARCHAR(500),
    last_seen_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_devices_utilisateur ON devices(utilisateur_id);
CREATE INDEX idx_devices_etablissement ON devices(etablissement_id);

-- ===========================================
-- SESSIONS (Refresh Tokens)
-- ===========================================
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    utilisateur_id UUID REFERENCES utilisateurs(id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(255) NOT NULL,
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_sessions_utilisateur ON sessions(utilisateur_id);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);

-- ===========================================
-- OTP (SMS Validation)
-- ===========================================
CREATE TABLE IF NOT EXISTS otp_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    utilisateur_id UUID REFERENCES utilisateurs(id) ON DELETE CASCADE,
    code VARCHAR(6) NOT NULL,
    purpose VARCHAR(50) NOT NULL, -- 'registration', 'login', 'password_reset'
    telephone VARCHAR(20) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_used BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_otp_utilisateur ON otp_codes(utilisateur_id);
CREATE INDEX idx_otp_expires_at ON otp_codes(expires_at);

-- ===========================================
-- ENREGISTREMENTS AUDIO
-- ===========================================
CREATE TABLE IF NOT EXISTS enregistrements_audio (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    utilisateur_id UUID REFERENCES utilisateurs(id) ON DELETE SET NULL,
    etablissement_id UUID REFERENCES etablissements(id) ON DELETE SET NULL,
    device_id UUID REFERENCES devices(id) ON DELETE SET NULL,
    fichier_url VARCHAR(500),
    fichier_s3_key VARCHAR(500),
    duree_seconds INTEGER,
    taille_bytes BIGINT,
    format VARCHAR(20),
    statut VARCHAR(50) DEFAULT 'pending' CHECK (statut IN ('pending', 'processing', 'identified', 'failed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_enregistrements_utilisateur ON enregistrements_audio(utilisateur_id);
CREATE INDEX idx_enregistrements_etablissement ON enregistrements_audio(etablissement_id);
CREATE INDEX idx_enregistrements_statut ON enregistrements_audio(statut);

-- ===========================================
-- RECONNAISSANCES MUSICALES
-- ===========================================
CREATE TABLE IF NOT EXISTS reconnaissances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enregistrement_id UUID REFERENCES enregistrements_audio(id) ON DELETE CASCADE,
    titre VARCHAR(255),
    artiste VARCHAR(255),
    album VARCHAR(255),
    isrc VARCHAR(12),
    label VARCHAR(255),
    annee_sortie INTEGER,
    genre VARCHAR(100),
    confidence_score DECIMAL(5, 4), -- 0.0000 à 1.0000
    source VARCHAR(20) CHECK (source IN ('acrcloud', 'audd', 'manual')),
    metadata_json JSONB,
    identified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reconnaissances_enregistrement ON reconnaissances(enregistrement_id);
CREATE INDEX idx_reconnaissances_artiste ON reconnaissances(artiste);
CREATE INDEX idx_reconnaissances_titre ON reconnaissances(titre);

-- ===========================================
-- DIFFUSIONS (Logs de diffusion musicale)
-- ===========================================
CREATE TABLE IF NOT EXISTS diffusions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    etablissement_id UUID REFERENCES etablissements(id) ON DELETE CASCADE,
    reconnaissance_id UUID REFERENCES reconnaissances(id) ON DELETE SET NULL,
    titre VARCHAR(255),
    artiste VARCHAR(255),
    isrc VARCHAR(12),
    diffuse_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    duree_ecoute_seconds INTEGER,
    metadata_json JSONB
);

CREATE INDEX idx_diffusions_etablissement ON diffusions(etablissement_id);
CREATE INDEX idx_diffusions_artiste ON diffusions(artiste);
CREATE INDEX idx_diffusions_date ON diffusions(diffuse_at);

-- ===========================================
-- TRIGGER: updated_at
-- ===========================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer le trigger aux tables avec updated_at
CREATE TRIGGER update_utilisateurs_updated_at
    BEFORE UPDATE ON utilisateurs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_etablissements_updated_at
    BEFORE UPDATE ON etablissements
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_devices_updated_at
    BEFORE UPDATE ON devices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ===========================================
-- DONNÉES DE TEST (Optionnel - Développement)
-- ===========================================
-- Admin par défaut (mot de passe: Admin123!)
-- À décommenter pour le développement uniquement
/*
INSERT INTO utilisateurs (email, password_hash, nom, prenom, role, is_verified)
VALUES (
    'admin@hmis-project.ci',
    '$2a$10$YourHashedPasswordHere',
    'Admin',
    'HMIS',
    'admin',
    true
) ON CONFLICT (email) DO NOTHING;
*/
