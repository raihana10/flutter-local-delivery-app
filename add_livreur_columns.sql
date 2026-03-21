-- ============================================================
-- SCRIPT POUR AJOUTER LES COLONNES MANQUANTES A LA TABLE LIVREUR
-- ============================================================

ALTER TABLE livreur
ADD COLUMN IF NOT EXISTS type_vehicule VARCHAR(50),
ADD COLUMN IF NOT EXISTS permis_conduire_image VARCHAR(255),
ADD COLUMN IF NOT EXISTS cni_recto_image VARCHAR(255),
ADD COLUMN IF NOT EXISTS cni_verso_image VARCHAR(255),
ADD COLUMN IF NOT EXISTS pdp VARCHAR(255); -- photo de profil

-- Optionnel: Si vous voulez ajouter une contrainte sur le type de véhicule
-- ALTER TABLE livreur ADD CONSTRAINT chk_type_vehicule 
-- CHECK (type_vehicule IN ('Vélo', 'Scooter / Moto', 'Voiture', 'Camionnette', 'Piéton', 'Autre'));
