-- ============================================================
--  SCHÉMA POSTGRESQL – Application de Livraison
--  Généré depuis MCDLivraison_drawio.html
--  Inclut : created_at, updated_at, deleted_at sur chaque table
-- ============================================================

-- Extension utile pour les UUID (optionnel)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TYPES ENUM
-- ============================================================

CREATE TYPE sexe_enum           AS ENUM ('homme', 'femme');
CREATE TYPE role_enum           AS ENUM ('client', 'livreur', 'business', 'super_admin');
CREATE TYPE type_business_enum  AS ENUM ('restaurant', 'super-marche', 'pharmacie');
CREATE TYPE type_produit_enum   AS ENUM ('meal', 'grocery', 'pharmacy');
CREATE TYPE statut_commande_enum AS ENUM ('confirmee', 'preparee', 'en_livraison', 'livree');
CREATE TYPE type_commande_enum  AS ENUM ('shopping', 'food_delivery');
CREATE TYPE statut_reclamation_enum AS ENUM ('en_attente', 'resolue');
CREATE TYPE statut_timeline_enum AS ENUM ('confirmee', 'preparee', 'en_livraison', 'livree');


-- ============================================================
-- TABLE : user  (compte commun : client / livreur / business)
-- ============================================================
CREATE TABLE "user" (
    id_user        SERIAL PRIMARY KEY,
    email          VARCHAR(255) NOT NULL UNIQUE,
    password       VARCHAR(255) NOT NULL,
    nom            VARCHAR(100),
    num_tl         VARCHAR(20),
    role           role_enum   NOT NULL DEFAULT 'client',
    est_actif      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at     TIMESTAMPTZ
);

-- ============================================================
-- TABLE : super_admin
-- ============================================================
CREATE TABLE super_admin (
    id_super_admin SERIAL PRIMARY KEY,
    id_user        INT         NOT NULL UNIQUE
                               REFERENCES "user"(id_user)
                               ON DELETE CASCADE,
    email          VARCHAR(255) NOT NULL UNIQUE,
    password       VARCHAR(255) NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at     TIMESTAMPTZ
);

-- ============================================================
-- TABLE : client
-- ============================================================
CREATE TABLE client (
    id_client      SERIAL PRIMARY KEY,
    id_user        INT         NOT NULL UNIQUE
                               REFERENCES "user"(id_user)
                               ON DELETE CASCADE,
    sexe           sexe_enum,
    date_naissance DATE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at     TIMESTAMPTZ
);

-- ============================================================
-- TABLE : livreur
-- ============================================================
CREATE TABLE livreur (
    id_livreur     SERIAL PRIMARY KEY,
    id_user        INT         NOT NULL UNIQUE
                               REFERENCES "user"(id_user)
                               ON DELETE CASCADE,
    sexe           sexe_enum,
    date_naissance DATE,
    cni            VARCHAR(50),
    est_actif      BOOLEAN     NOT NULL DEFAULT FALSE,  -- validé après vérif docs
    documents_validation BOOLEAN NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at     TIMESTAMPTZ
);

-- ============================================================
-- TABLE : business
-- ============================================================
CREATE TABLE business (
    id_business        SERIAL PRIMARY KEY,
    id_user            INT         NOT NULL UNIQUE
                                   REFERENCES "user"(id_user)
                                   ON DELETE CASCADE,
    type_business      type_business_enum NOT NULL,
    description        TEXT,
    pdp                VARCHAR(255),           -- photo de profil
    opening_hours      JSONB,                  -- ex: {"lun":"08:00-22:00",...}
    temps_preparation  INT,                    -- minutes
    is_open            BOOLEAN     NOT NULL DEFAULT FALSE,
    documents_validation BOOLEAN   NOT NULL DEFAULT FALSE,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at         TIMESTAMPTZ
);

-- ============================================================
-- TABLE : adresse
-- ============================================================
CREATE TABLE adresse (
    id_adresse  SERIAL PRIMARY KEY,
    id_user     INT         NOT NULL
                            REFERENCES "user"(id_user)
                            ON DELETE CASCADE,
    ville       VARCHAR(100),
    latitude    DECIMAL(10, 7) NOT NULL,
    longitude   DECIMAL(10, 7) NOT NULL,
    is_default  BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

-- ============================================================
-- TABLE : produit
-- ============================================================
CREATE TABLE produit (
    id_produit    SERIAL PRIMARY KEY,
    nom_produit   VARCHAR(255) NOT NULL,
    description   TEXT,
    image         VARCHAR(255),
    type_produit  type_produit_enum NOT NULL,
    marque        VARCHAR(100),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at    TIMESTAMPTZ
);

-- ============================================================
-- TABLE : variante_produit
-- ============================================================
CREATE TABLE variante_produit (
    id_variante  SERIAL PRIMARY KEY,
    id_produit   INT         NOT NULL
                             REFERENCES produit(id_produit)
                             ON DELETE CASCADE,
    nom_variante VARCHAR(255) NOT NULL,
    attributs    JSONB,       -- ex: {"taille":"L","couleur":"rouge"}
    image        VARCHAR(255),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at   TIMESTAMPTZ
);

-- ============================================================
-- TABLE : business_produit  (associe une variante à un business)
-- ============================================================
CREATE TABLE business_produit (
    id_business_produit SERIAL PRIMARY KEY,
    id_business         INT          NOT NULL
                                     REFERENCES business(id_business)
                                     ON DELETE CASCADE,
    id_variante         INT          NOT NULL
                                     REFERENCES variante_produit(id_variante)
                                     ON DELETE CASCADE,
    prix_vente          NUMERIC(10,2) NOT NULL CHECK (prix_vente >= 0),
    est_dispo           BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ,
    UNIQUE (id_business, id_variante)
);

-- ============================================================
-- TABLE : promotion
-- ============================================================
CREATE TABLE promotion (
    id_promotion  SERIAL PRIMARY KEY,
    pourcentage   NUMERIC(5,2) NOT NULL
                               CHECK (pourcentage > 0 AND pourcentage <= 100),
    code_pro      VARCHAR(50)  UNIQUE,
    date_debut    TIMESTAMPTZ  NOT NULL,
    date_fin      TIMESTAMPTZ  NOT NULL,
    CHECK (date_fin > date_debut),
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at    TIMESTAMPTZ
);

-- ============================================================
-- TABLE : promotion_variante  (promotion concerne des variantes)
-- ============================================================
CREATE TABLE promotion_variante (
    id_promotion  INT NOT NULL REFERENCES promotion(id_promotion)  ON DELETE CASCADE,
    id_variante   INT NOT NULL REFERENCES variante_produit(id_variante) ON DELETE CASCADE,
    PRIMARY KEY (id_promotion, id_variante),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at    TIMESTAMPTZ
);

-- ============================================================
-- TABLE : commande
-- ============================================================
CREATE TABLE commande (
    id_commande       SERIAL PRIMARY KEY,
    id_client         INT         NOT NULL
                                  REFERENCES client(id_client),
    id_adresse        INT
                                  REFERENCES adresse(id_adresse),
    statut_commande   statut_commande_enum NOT NULL DEFAULT 'confirmee',
    type_commande     type_commande_enum   NOT NULL,
    prix_total        NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (prix_total >= 0),
    prix_donne        NUMERIC(10,2),  -- montant réellement payé (après promo)
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at        TIMESTAMPTZ
);

-- ============================================================
-- TABLE : ligne_commande
-- ============================================================
CREATE TABLE ligne_commande (
    id_lc               SERIAL PRIMARY KEY,
    id_commande         INT          NOT NULL
                                     REFERENCES commande(id_commande)
                                     ON DELETE CASCADE,
    id_business_produit INT          NOT NULL
                                     REFERENCES business_produit(id_business_produit),
    quantite            INT          NOT NULL CHECK (quantite > 0),
    prix_snapshot       NUMERIC(10,2) NOT NULL CHECK (prix_snapshot >= 0),
    nom_snapshot        VARCHAR(255) NOT NULL,
    attributs_snapshot  JSONB,
    total_ligne         NUMERIC(10,2) GENERATED ALWAYS AS (quantite * prix_snapshot) STORED,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ
);

-- ============================================================
-- TABLE : timeline
-- ============================================================
CREATE TABLE timeline (
    id_timeline        SERIAL PRIMARY KEY,
    id_commande        INT         NOT NULL UNIQUE
                                   REFERENCES commande(id_commande)
                                   ON DELETE CASCADE,
    id_livreur         INT
                                   REFERENCES livreur(id_livreur),
    statut_tmlne       statut_timeline_enum NOT NULL DEFAULT 'confirmee',
    estimated_at       TIMESTAMPTZ,
    remaining_time     INT,          -- secondes restantes
    remaining_distance DECIMAL(10,2),-- km restants
    position_order     JSONB,        -- position GPS du livreur
    attribute          TEXT,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at         TIMESTAMPTZ
);

-- ============================================================
-- TABLE : store_review  (avis sur un business)
-- ============================================================
CREATE TABLE store_review (
    id_s_review   SERIAL PRIMARY KEY,
    id_client     INT         NOT NULL REFERENCES client(id_client),
    id_business   INT         NOT NULL REFERENCES business(id_business),
    evaluation    SMALLINT    NOT NULL CHECK (evaluation BETWEEN 1 AND 5),
    commentaire   TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at    TIMESTAMPTZ,
    UNIQUE (id_client, id_business)
);

-- ============================================================
-- TABLE : order_review  (avis sur une commande)
-- ============================================================
CREATE TABLE order_review (
    id_o_review  SERIAL PRIMARY KEY,
    id_commande  INT         NOT NULL UNIQUE
                             REFERENCES commande(id_commande),
    id_client    INT         NOT NULL REFERENCES client(id_client),
    evaluation   SMALLINT    NOT NULL CHECK (evaluation BETWEEN 1 AND 5),
    commentaire  TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at   TIMESTAMPTZ
);

-- ============================================================
-- TABLE : favoris  (est_favoris : client ↔ business)
-- ============================================================
CREATE TABLE favoris (
    id_client    INT NOT NULL REFERENCES client(id_client)   ON DELETE CASCADE,
    id_business  INT NOT NULL REFERENCES business(id_business) ON DELETE CASCADE,
    PRIMARY KEY (id_client, id_business),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at   TIMESTAMPTZ
);

-- ============================================================
-- TABLE : notification
-- ============================================================
CREATE TABLE notification (
    id_not       SERIAL PRIMARY KEY,
    id_user      INT         NOT NULL REFERENCES "user"(id_user) ON DELETE CASCADE,
    titre        VARCHAR(255),
    message      TEXT,
    type         VARCHAR(50),
    est_lu       BOOLEAN     NOT NULL DEFAULT FALSE,
    date         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at   TIMESTAMPTZ
);

-- ============================================================
-- TABLE : reclamation
-- ============================================================
CREATE TABLE reclamation (
    id_reclamation      SERIAL PRIMARY KEY,
    id_user             INT         NOT NULL REFERENCES "user"(id_user),
    id_super_admin      INT
                                    REFERENCES super_admin(id_super_admin),
    description         TEXT        NOT NULL,
    statut_reclamation  statut_reclamation_enum NOT NULL DEFAULT 'en_attente',
    date_reclamation    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    preuve              VARCHAR(255),   -- chemin/URL vers le fichier preuve
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ
);

-- ============================================================
-- TRIGGER : mise à jour automatique de updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Applique le trigger à toutes les tables
DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        '"user"', 'super_admin', 'client', 'livreur', 'business',
        'adresse', 'produit', 'variante_produit', 'business_produit',
        'promotion', 'promotion_variante', 'commande', 'ligne_commande',
        'timeline', 'store_review', 'order_review', 'favoris',
        'notification', 'reclamation'
    ]
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_%s_updated_at
             BEFORE UPDATE ON %s
             FOR EACH ROW EXECUTE FUNCTION set_updated_at();',
            replace(replace(t, '"', ''), '.', '_'), t
        );
    END LOOP;
END;
$$;

-- ============================================================
-- INDEX UTILES
-- ============================================================

-- Soft-delete : on filtre souvent sur deleted_at IS NULL
CREATE INDEX idx_user_deleted_at             ON "user"(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_client_deleted_at           ON client(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_livreur_deleted_at          ON livreur(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_business_deleted_at         ON business(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_produit_deleted_at          ON produit(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_commande_deleted_at         ON commande(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_ligne_commande_deleted_at   ON ligne_commande(deleted_at) WHERE deleted_at IS NULL;

-- FK fréquemment jointes
CREATE INDEX idx_adresse_user               ON adresse(id_user);
CREATE INDEX idx_commande_client            ON commande(id_client);
CREATE INDEX idx_commande_statut            ON commande(statut_commande);
CREATE INDEX idx_ligne_commande_commande    ON ligne_commande(id_commande);
CREATE INDEX idx_timeline_commande          ON timeline(id_commande);
CREATE INDEX idx_notification_user          ON notification(id_user);
CREATE INDEX idx_reclamation_user           ON reclamation(id_user);
CREATE INDEX idx_business_produit_business  ON business_produit(id_business);
CREATE INDEX idx_business_produit_variante  ON business_produit(id_variante);
CREATE INDEX idx_variante_produit           ON variante_produit(id_produit);
