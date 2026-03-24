-- ============================================================
--  SCHÉMA POSTGRESQL – Application de Livraison
--  Généré depuis MCDLivraison_drawio.html
-- ============================================================

-- Extension utile pour les UUID (optionnel)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Nécessaire pour la contrainte d'exclusion sur promotion
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ============================================================
-- TYPES ENUM
-- ============================================================

CREATE TYPE sexe_enum            AS ENUM ('homme', 'femme');
CREATE TYPE role_enum            AS ENUM ('client', 'livreur', 'business');
CREATE TYPE type_business_enum   AS ENUM ('restaurant', 'super-marche', 'pharmacie');
CREATE TYPE type_produit_enum    AS ENUM ('meal', 'grocery', 'pharmacy');
CREATE TYPE statut_commande_enum AS ENUM ('confirmee', 'preparee', 'en_livraison', 'livree');
CREATE TYPE type_commande_enum   AS ENUM ('shopping', 'food_delivery');
CREATE TYPE statut_timeline_enum AS ENUM ('confirmee', 'preparee', 'en_livraison', 'livree');


-- ============================================================
-- TABLE : user  (compte commun : client / livreur / business)
-- ============================================================
CREATE TABLE app_user (
    id_user        SERIAL PRIMARY KEY,
    email          VARCHAR(255) NOT NULL UNIQUE,
    password       VARCHAR(255) NOT NULL,
    nom            VARCHAR(100),
    num_tl         VARCHAR(20),
    role           role_enum   NOT NULL DEFAULT 'client',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at     TIMESTAMPTZ
);

-- ============================================================
-- TABLE : admin
-- ============================================================
CREATE TABLE admin (
    id_admin       SERIAL PRIMARY KEY,
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
                               REFERENCES app_user(id_user)
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
                               REFERENCES app_user(id_user)
                               ON DELETE CASCADE,
    sexe           sexe_enum,
    date_naissance DATE,
    cni            VARCHAR(50),
    est_actif      BOOLEAN     NOT NULL DEFAULT FALSE,
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
                                   REFERENCES app_user(id_user)
                                   ON DELETE CASCADE,
    type_business      type_business_enum NOT NULL,
    description        TEXT,
    pdp                VARCHAR(255),           -- photo de profil
    opening_hours      JSONB,                  -- ex: {"lun":"08:00-22:00",...}
    temps_preparation  INT,                    -- minutes
    is_open            BOOLEAN     NOT NULL DEFAULT FALSE,
    est_actif          BOOLEAN     NOT NULL DEFAULT FALSE,
    documents_validation VARCHAR(255),         -- chemin/URL vers le fichier soumis
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at         TIMESTAMPTZ
);

-- ============================================================
-- TABLE : adresse  (entité indépendante — N-N avec user via user_adresse)
-- ============================================================
CREATE TABLE adresse (
    id_adresse  SERIAL PRIMARY KEY,
    ville       VARCHAR(100),
    latitude    DECIMAL(10, 7) NOT NULL,
    longitude   DECIMAL(10, 7) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

-- ============================================================
-- TABLE : user_adresse  (association user ↔ adresse, relation "admet" N-N)
-- ============================================================
CREATE TABLE user_adresse (
    id_user     INT     NOT NULL REFERENCES app_user(id_user)     ON DELETE CASCADE,
    id_adresse  INT     NOT NULL REFERENCES adresse(id_adresse) ON DELETE CASCADE,
    is_default  BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_user, id_adresse),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

-- ============================================================
-- TABLE : carte_bancaire
-- ============================================================
CREATE TABLE carte_bancaire (
    id_carte       SERIAL PRIMARY KEY,
    id_client      INT         NOT NULL REFERENCES client(id_client) ON DELETE CASCADE,
    numero_carte   VARCHAR(50) NOT NULL,
    date_expiration VARCHAR(10) NOT NULL,
    nom_carte      VARCHAR(100),
    is_default     BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at     TIMESTAMPTZ
);

-- ============================================================
-- TABLE : produit
-- ============================================================
CREATE TABLE produit (
    id_produit    SERIAL PRIMARY KEY,
    id_business   INT          NOT NULL
                               REFERENCES business(id_business)
                               ON DELETE CASCADE,
    nom_produit   VARCHAR(255) NOT NULL,
    description   TEXT,
    image         VARCHAR(255),
    type_produit  type_produit_enum NOT NULL,
    prix_unitaire NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (prix_unitaire >= 0),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at    TIMESTAMPTZ
);

-- ============================================================
-- TABLE : promotion
-- ============================================================
CREATE TABLE promotion (
    id_promotion  SERIAL PRIMARY KEY,
    id_produit    INT          NOT NULL
                               REFERENCES produit(id_produit)
                               ON DELETE CASCADE,
    pourcentage   NUMERIC(5,2) NOT NULL
                               CHECK (pourcentage > 0 AND pourcentage <= 100),
    date_debut    TIMESTAMPTZ  NOT NULL,
    date_fin      TIMESTAMPTZ  NOT NULL,
    CHECK (date_fin > date_debut),
    -- Un produit ne peut avoir qu'une seule promotion active à la fois
    EXCLUDE USING gist (
        id_produit WITH =,
        tstzrange(date_debut, date_fin, '[)') WITH &&
    ),
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
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
    id_produit          INT          NOT NULL
                                     REFERENCES produit(id_produit),
    quantite            INT          NOT NULL CHECK (quantite > 0),
    prix_snapshot       NUMERIC(10,2) NOT NULL CHECK (prix_snapshot >= 0),
    nom_snapshot        VARCHAR(255) NOT NULL,
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
    id_client    INT NOT NULL REFERENCES client(id_client)     ON DELETE CASCADE,
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
    titre        VARCHAR(255),
    message      TEXT,
    type         VARCHAR(50),
    date         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at   TIMESTAMPTZ
);

-- ============================================================
-- TABLE : user_notification  (recoit : user ↔ notification, relation N-N)
-- ============================================================
CREATE TABLE user_notification (
    id_user_notification SERIAL PRIMARY KEY,
    id_user  INT NOT NULL REFERENCES app_user(id_user)      ON DELETE CASCADE,
    id_not   INT NOT NULL REFERENCES notification(id_not) ON DELETE CASCADE,
    est_lu   BOOLEAN     NOT NULL DEFAULT FALSE,
    lu_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    UNIQUE (id_user, id_not)
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
        'app_user', 'admin', 'client', 'livreur', 'business',
        'adresse', 'user_adresse', 'produit', 'promotion',
        'commande', 'ligne_commande', 'timeline',
        'store_review', 'order_review', 'favoris',
        'notification', 'user_notification'
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

-- Trigger spécifique pour carte_bancaire
CREATE TRIGGER trg_carte_bancaire_updated_at
BEFORE UPDATE ON carte_bancaire
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- TABLE : favoris (Client favorite businesses)
-- ============================================================
CREATE TABLE favoris (
    id_favoris     SERIAL PRIMARY KEY,
    id_client      INT         NOT NULL REFERENCES client(id_client) ON DELETE CASCADE,
    id_business    INT         NOT NULL REFERENCES business(id_business) ON DELETE CASCADE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(id_client, id_business)
);

-- ============================================================
-- INDEX UTILES
-- ============================================================

-- Soft-delete : on filtre souvent sur deleted_at IS NULL
CREATE INDEX idx_user_deleted_at             ON app_user(deleted_at)         WHERE deleted_at IS NULL;
CREATE INDEX idx_client_deleted_at           ON client(deleted_at)         WHERE deleted_at IS NULL;
CREATE INDEX idx_livreur_deleted_at          ON livreur(deleted_at)        WHERE deleted_at IS NULL;
CREATE INDEX idx_business_deleted_at         ON business(deleted_at)       WHERE deleted_at IS NULL;
CREATE INDEX idx_produit_deleted_at          ON produit(deleted_at)        WHERE deleted_at IS NULL;
CREATE INDEX idx_commande_deleted_at         ON commande(deleted_at)       WHERE deleted_at IS NULL;
CREATE INDEX idx_ligne_commande_deleted_at   ON ligne_commande(deleted_at) WHERE deleted_at IS NULL;

-- FK fréquemment jointes
CREATE INDEX idx_user_adresse_user           ON user_adresse(id_user);
CREATE INDEX idx_user_adresse_adresse        ON user_adresse(id_adresse);
CREATE INDEX idx_produit_business            ON produit(id_business);
CREATE INDEX idx_promotion_produit           ON promotion(id_produit);
CREATE INDEX idx_commande_client             ON commande(id_client);
CREATE INDEX idx_commande_adresse            ON commande(id_adresse);
CREATE INDEX idx_commande_statut             ON commande(statut_commande);
CREATE INDEX idx_ligne_commande_commande     ON ligne_commande(id_commande);
CREATE INDEX idx_ligne_commande_produit      ON ligne_commande(id_produit);
CREATE INDEX idx_timeline_commande           ON timeline(id_commande);
CREATE INDEX idx_user_notification_user      ON user_notification(id_user);
