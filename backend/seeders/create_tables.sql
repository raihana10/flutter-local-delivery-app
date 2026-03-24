-- Tables pour le dashboard et les statistiques
-- Exécuter ce script dans votre projet Supabase (SQL Editor)

-- Table pour l'évolution des revenus (7 derniers jours)
CREATE TABLE IF NOT EXISTS dashboard_revenue_evolution (
  id SERIAL PRIMARY KEY,
  day VARCHAR(10) NOT NULL,
  date DATE NOT NULL,
  revenue DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Table pour le statut des commandes (pie chart)
CREATE TABLE IF NOT EXISTS dashboard_orders_status (
  id SERIAL PRIMARY KEY,
  status VARCHAR(50) NOT NULL,
  count INTEGER NOT NULL,
  color VARCHAR(7) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Table pour les revenus hebdomadaires
CREATE TABLE IF NOT EXISTS dashboard_weekly_revenue (
  id SERIAL PRIMARY KEY,
  current_week DECIMAL(10, 2) NOT NULL,
  previous_week DECIMAL(10, 2) NOT NULL,
  growth_percentage DECIMAL(5, 2) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Table pour les top livreurs
CREATE TABLE IF NOT EXISTS dashboard_top_livreurs (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  deliveries INTEGER NOT NULL,
  rating DECIMAL(3, 1) NOT NULL,
  revenue DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Table pour les top commerce
CREATE TABLE IF NOT EXISTS dashboard_top_commerce (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  type VARCHAR(20) NOT NULL,
  revenue DECIMAL(10, 2) NOT NULL,
  orders INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Tables pour les statistiques détaillées

-- Table pour les revenus hebdomadaires détaillés
CREATE TABLE IF NOT EXISTS stats_weekly_revenue (
  id SERIAL PRIMARY KEY,
  current_week_revenue DECIMAL(10, 2) NOT NULL,
  previous_week_revenue DECIMAL(10, 2) NOT NULL,
  growth_percentage DECIMAL(5, 2) NOT NULL,
  daily_average DECIMAL(10, 2) NOT NULL,
  best_day VARCHAR(20) NOT NULL,
  best_day_revenue DECIMAL(10, 2) NOT NULL,
  transactions_count INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Table pour les top livreurs détaillés
CREATE TABLE IF NOT EXISTS stats_top_livreurs (
  id SERIAL PRIMARY KEY,
  id_user INTEGER NOT NULL,
  nom VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL,
  deliveries_count INTEGER NOT NULL,
  rating DECIMAL(3, 1) NOT NULL,
  total_revenue DECIMAL(10, 2) NOT NULL,
  avg_delivery_time INTEGER NOT NULL,
  completion_rate DECIMAL(5, 2) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Table pour les top commerce détaillés
CREATE TABLE IF NOT EXISTS stats_top_commerce (
  id SERIAL PRIMARY KEY,
  id_user INTEGER NOT NULL,
  nom VARCHAR(100) NOT NULL,
  type VARCHAR(20) NOT NULL,
  revenue DECIMAL(10, 2) NOT NULL,
  orders_count INTEGER NOT NULL,
  avg_order_value DECIMAL(10, 2) NOT NULL,
  rating DECIMAL(3, 1) NOT NULL,
  active_products INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Activer RLS (Row Level Security) pour toutes les tables
ALTER TABLE dashboard_revenue_evolution ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_orders_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_weekly_revenue ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_top_livreurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_top_commerce ENABLE ROW LEVEL SECURITY;
ALTER TABLE stats_weekly_revenue ENABLE ROW LEVEL SECURITY;
ALTER TABLE stats_top_livreurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE stats_top_commerce ENABLE ROW LEVEL SECURITY;

-- Politiques RLS pour permettre les lectures/écritures
CREATE POLICY "Enable all operations on dashboard_revenue_evolution" ON dashboard_revenue_evolution FOR ALL USING (true);
CREATE POLICY "Enable all operations on dashboard_orders_status" ON dashboard_orders_status FOR ALL USING (true);
CREATE POLICY "Enable all operations on dashboard_weekly_revenue" ON dashboard_weekly_revenue FOR ALL USING (true);
CREATE POLICY "Enable all operations on dashboard_top_livreurs" ON dashboard_top_livreurs FOR ALL USING (true);
CREATE POLICY "Enable all operations on dashboard_top_commerce" ON dashboard_top_commerce FOR ALL USING (true);
CREATE POLICY "Enable all operations on stats_weekly_revenue" ON stats_weekly_revenue FOR ALL USING (true);
CREATE POLICY "Enable all operations on stats_top_livreurs" ON stats_top_livreurs FOR ALL USING (true);
CREATE POLICY "Enable all operations on stats_top_commerce" ON stats_top_commerce FOR ALL USING (true);
