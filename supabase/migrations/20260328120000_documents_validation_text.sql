-- Plusieurs URLs ou chemins de stockage dépassent VARCHAR(255).
-- Exécuter ce script dans le SQL Editor Supabase si les colonnes existent déjà en VARCHAR.

ALTER TABLE livreur
  ADD COLUMN IF NOT EXISTS documents_validation TEXT;

ALTER TABLE business
  ALTER COLUMN documents_validation TYPE TEXT;
